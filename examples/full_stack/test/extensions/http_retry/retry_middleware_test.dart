import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/http_retry/retry_budget.dart';
import 'package:full_stack/extensions/http_retry/retry_events.dart';
import 'package:full_stack/extensions/http_retry/retry_middleware.dart';
import 'package:full_stack/extensions/http_retry/retry_settings.dart';

HttpRequest _request({
  HttpMethod method = HttpMethod.get,
  Map<String, String> headers = const <String, String>{},
  DateTime? deadline,
}) {
  return HttpRequest(
    method: method,
    uri: Uri.parse('https://api.kiln.dev/users'),
    headers: headers,
    deadline: deadline,
  );
}

const _settings = HttpRetrySettings(
  maxAttempts: 3,
  initialDelay: Duration(milliseconds: 1),
  maxDelay: Duration(milliseconds: 1),
  jitter: false,
  retryableStatusCodes: <int>{503},
);

void main() {
  for (final networkFailure in [false, true]) {
    test(
      'cancels a pending retry wait after ${networkFailure ? 'failure' : 'response'}',
      () async {
        final token = HttpCancelToken();
        final waiting = Completer<void>();
        final delayed = Completer<void>();
        final middleware = RetryMiddleware(
          settings: _settings,
          delay: (_) {
            waiting.complete();
            return delayed.future;
          },
        );
        var attempts = 0;
        final result = middleware.handle(
          _request().copyWith(cancelToken: token),
          (_) async {
            attempts++;
            if (networkFailure) {
              throw const Failure(
                code: FailureCode.networkTimeout,
                message: 'Temporary network failure.',
                kind: FailureKind.network,
                isRetryable: true,
              );
            }
            return const HttpResponse(statusCode: 503);
          },
        );
        final expectation = expectLater(
          result,
          throwsA(
            isA<Failure>().having((f) => f.code, 'code', FailureCode.cancelled),
          ),
        );
        await waiting.future;
        token.cancel();
        await expectation.timeout(const Duration(seconds: 1));
        expect(attempts, 1);
        delayed.complete();
      },
    );
  }

  test('retries a retryable status and returns the next success', () async {
    var calls = 0;
    final delays = <Duration>[];
    final retries = <RetryEvent>[];
    final middleware = RetryMiddleware(
      settings: _settings,
      budget: RetryBudget(),
      events: RetryEvents(onRetry: retries.add),
      delay: (delay) async => delays.add(delay),
    );

    final response = await middleware.handle(_request(), (_) async {
      calls++;
      return HttpResponse(statusCode: calls < 3 ? 503 : 200);
    });

    expect(response.statusCode, 200);
    expect(calls, 3);
    expect(retries, hasLength(2));
    expect(delays, hasLength(2));
  });

  test('retries a retryable Failure', () async {
    var calls = 0;
    final middleware = RetryMiddleware(
      settings: _settings,
      delay: (_) async {},
    );

    final response = await middleware.handle(_request(), (_) async {
      calls++;
      if (calls == 1) {
        throw const Failure(
          code: FailureCode.networkTimeout,
          message: 'timeout',
          kind: FailureKind.network,
          isRetryable: true,
        );
      }
      return const HttpResponse(statusCode: 200);
    });

    expect(response.statusCode, 200);
    expect(calls, 2);
  });

  test('does not retry a non-idempotent POST without a key', () async {
    var calls = 0;
    final middleware = RetryMiddleware(
      settings: _settings,
      delay: (_) async {},
    );

    final response = await middleware.handle(
      _request(method: HttpMethod.post),
      (_) async {
        calls++;
        return const HttpResponse(statusCode: 503);
      },
    );

    expect(response.statusCode, 503);
    expect(calls, 1);
  });

  test('retries a POST with an Idempotency-Key', () async {
    var calls = 0;
    final middleware = RetryMiddleware(
      settings: _settings,
      delay: (_) async {},
    );

    final response = await middleware.handle(
      _request(
        method: HttpMethod.post,
        headers: const {'Idempotency-Key': 'req-1'},
      ),
      (_) async {
        calls++;
        return HttpResponse(statusCode: calls == 1 ? 503 : 200);
      },
    );

    expect(response.statusCode, 200);
    expect(calls, 2);
  });

  test('clamps Retry-After to the configured ceiling', () async {
    final delays = <Duration>[];
    final middleware = RetryMiddleware(
      settings: _settings,
      delay: (delay) async => delays.add(delay),
    );

    await middleware.handle(_request(), (_) async {
      if (delays.isEmpty) {
        return const HttpResponse(
          statusCode: 503,
          headers: {
            'Retry-After': ['2'],
          },
        );
      }
      return const HttpResponse(statusCode: 200);
    });

    expect(delays.single, _settings.maxDelay);
  });

  test('stops when the retry budget is exhausted', () async {
    var calls = 0;
    final giveUps = <RetryEvent>[];
    final middleware = RetryMiddleware(
      settings: _settings,
      budget: RetryBudget(maxRetries: 1),
      events: RetryEvents(onGiveUp: giveUps.add),
      delay: (_) async {},
    );

    final response = await middleware.handle(_request(), (_) async {
      calls++;
      return const HttpResponse(statusCode: 503);
    });

    expect(response.statusCode, 503);
    expect(calls, 2);
    expect(giveUps, isNotEmpty);
  });

  test('shares retry budget per host across dynamic paths', () async {
    final budget = RetryBudget(maxRetries: 1);
    final middleware = RetryMiddleware(
      settings: _settings,
      budget: budget,
      delay: (_) async {},
    );

    var firstCalls = 0;
    await middleware.handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/users/1'),
      ),
      (_) async {
        firstCalls++;
        return const HttpResponse(statusCode: 503);
      },
    );
    expect(firstCalls, 2);

    var secondCalls = 0;
    await middleware.handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/users/2'),
      ),
      (_) async {
        secondCalls++;
        return const HttpResponse(statusCode: 503);
      },
    );
    expect(secondCalls, 1);
  });

  group('total budget', () {
    HttpRetrySettings budgeted(Duration budget) => HttpRetrySettings(
      maxAttempts: 5,
      initialDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 100),
      jitter: false,
      totalBudget: budget,
      retryableStatusCodes: const <int>{503},
    );

    test('stops retrying when the wall-clock budget is spent', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 21));
      final delays = <Duration>[];
      var attempts = 0;
      final middleware = RetryMiddleware(
        settings: budgeted(const Duration(milliseconds: 250)),
        clock: clock,
        delay: (delay) async {
          delays.add(delay);
          clock.advance(delay);
        },
      );

      final response = await middleware.handle(_request(), (_) async {
        attempts++;
        return const HttpResponse(statusCode: 503);
      });

      expect(response.statusCode, 503);
      expect(attempts, 3);
      expect(delays, const <Duration>[
        Duration(milliseconds: 100),
        Duration(milliseconds: 100),
        Duration(milliseconds: 50),
      ]);
    });

    test('a budget shorter than the first delay allows one attempt', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 21));
      final delays = <Duration>[];
      var attempts = 0;
      final middleware = RetryMiddleware(
        settings: budgeted(const Duration(milliseconds: 30)),
        clock: clock,
        delay: (delay) async {
          delays.add(delay);
          clock.advance(delay);
        },
      );

      await middleware.handle(_request(), (_) async {
        attempts++;
        return const HttpResponse(statusCode: 503);
      });

      expect(attempts, 1);
      expect(delays, const <Duration>[Duration(milliseconds: 30)]);
    });

    test('clips a Retry-After wait to the remaining budget', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 21));
      Duration? waited;
      var attempts = 0;
      final middleware = RetryMiddleware(
        settings: HttpRetrySettings(
          maxAttempts: 5,
          initialDelay: const Duration(milliseconds: 100),
          maxDelay: const Duration(seconds: 8),
          jitter: false,
          totalBudget: const Duration(milliseconds: 500),
          retryableStatusCodes: const <int>{503},
        ),
        clock: clock,
        delay: (delay) async {
          waited = delay;
          clock.advance(delay);
        },
      );

      await middleware.handle(_request(), (_) async {
        attempts++;
        return const HttpResponse(
          statusCode: 503,
          headers: <String, List<String>>{
            'retry-after': <String>['30'],
          },
        );
      });

      expect(attempts, 1);
      expect(waited, const Duration(milliseconds: 500));
    });

    test('the failure branch also honours the budget', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 21));
      var attempts = 0;
      final middleware = RetryMiddleware(
        settings: budgeted(const Duration(milliseconds: 250)),
        clock: clock,
        delay: (delay) async => clock.advance(delay),
      );

      await expectLater(
        middleware.handle(_request(), (_) async {
          attempts++;
          throw const Failure(
            code: FailureCode.networkTimeout,
            message: 'Temporary network failure.',
            kind: FailureKind.network,
            isRetryable: true,
          );
        }),
        throwsA(isA<Failure>()),
      );

      expect(attempts, 3);
    });

    test('without a budget the attempt limit still applies', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 21));
      var attempts = 0;
      final middleware = RetryMiddleware(
        settings: HttpRetrySettings(
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
          maxDelay: const Duration(milliseconds: 10),
          jitter: false,
          retryableStatusCodes: const <int>{503},
        ),
        clock: clock,
        delay: (delay) async => clock.advance(delay),
      );

      await middleware.handle(_request(), (_) async {
        attempts++;
        return const HttpResponse(statusCode: 503);
      });

      expect(attempts, 3);
    });
  });

  group('request deadline', () {
    test('an expired deadline fails before the first attempt', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 21));
      var attempts = 0;
      final middleware = RetryMiddleware(
        settings: _settings,
        clock: clock,
        delay: (_) async {},
      );

      await expectLater(
        middleware.handle(
          _request(
            deadline: clock.now().subtract(const Duration(seconds: 1)),
          ),
          (_) async {
            attempts++;
            return const HttpResponse(statusCode: 200);
          },
        ),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.networkDeadlineExceeded,
          ),
        ),
      );
      expect(attempts, 0);
    });

    test('clips retry waits to the deadline and fails when it passes', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 21));
      final delays = <Duration>[];
      var attempts = 0;
      final middleware = RetryMiddleware(
        settings: HttpRetrySettings(
          maxAttempts: 5,
          initialDelay: const Duration(milliseconds: 100),
          maxDelay: const Duration(milliseconds: 100),
          jitter: false,
          retryableStatusCodes: const <int>{503},
        ),
        clock: clock,
        delay: (delay) async {
          delays.add(delay);
          clock.advance(delay);
        },
      );

      await expectLater(
        middleware.handle(
          _request(
            deadline: clock.now().add(const Duration(milliseconds: 250)),
          ),
          (_) async {
            attempts++;
            return const HttpResponse(statusCode: 503);
          },
        ),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.networkDeadlineExceeded,
          ),
        ),
      );

      expect(attempts, 3);
      expect(delays, const <Duration>[
        Duration(milliseconds: 100),
        Duration(milliseconds: 100),
        Duration(milliseconds: 50),
      ]);
    });

    test('a deadline after a successful retry does not interfere', () async {
      final clock = FixedClock(DateTime.utc(2026, 11, 21));
      var attempts = 0;
      final middleware = RetryMiddleware(
        settings: _settings,
        clock: clock,
        delay: (_) async {},
      );

      final response = await middleware.handle(
        _request(deadline: clock.now().add(const Duration(minutes: 1))),
        (_) async {
          attempts++;
          return HttpResponse(statusCode: attempts == 1 ? 503 : 200);
        },
      );

      expect(response.statusCode, 200);
      expect(attempts, 2);
    });
  });
}
