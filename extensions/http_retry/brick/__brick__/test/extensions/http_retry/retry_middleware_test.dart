import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_retry/retry_budget.dart';
import 'package:{{app_name}}/extensions/http_retry/retry_events.dart';
import 'package:{{app_name}}/extensions/http_retry/retry_middleware.dart';
import 'package:{{app_name}}/extensions/http_retry/retry_settings.dart';

HttpRequest _request({
  HttpMethod method = HttpMethod.get,
  Map<String, String> headers = const <String, String>{},
}) {
  return HttpRequest(
    method: method,
    uri: Uri.parse('https://api.kiln.dev/users'),
    headers: headers,
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

  test('uses Retry-After for the next delay', () async {
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

    expect(delays.single, const Duration(seconds: 2));
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
}
