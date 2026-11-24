import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'backoff.dart';
import 'retry_after_parser.dart';
import 'retry_budget.dart';
import 'retry_events.dart';
import 'retry_policy.dart';
import 'retry_settings.dart';

// The public injection seam intentionally keeps its name separate from _delay.
// ignore_for_file: prefer_initializing_formals

/// `HttpMiddleware` that retries transient failures.
final class RetryMiddleware implements HttpMiddleware {
  RetryMiddleware({
    this.settings = HttpRetrySettings.defaults,
    this.policy = const RetryPolicy(),
    RetryBudget? budget,
    this.events,
    Backoff? backoff,
    this.retryAfterParser = const RetryAfterParser(),
    Future<void> Function(Duration delay)? delay,
    this.clock = const SystemClock(),
  }) : budget = budget ?? RetryBudget(),
       backoff = backoff ?? Backoff(settings: settings),
       _delay = delay;

  final HttpRetrySettings settings;
  final RetryPolicy policy;
  final RetryBudget budget;
  final RetryEvents? events;
  final Backoff backoff;
  final RetryAfterParser retryAfterParser;
  final Clock clock;
  final Future<void> Function(Duration delay)? _delay;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    var attempt = 0;
    final startedAt = clock.now().toUtc();
    while (true) {
      request.cancelToken?.throwIfCancelled();
      request.throwIfDeadlineExceeded(clock.now().toUtc());
      attempt++;
      try {
        final response = await next(request);
        request.cancelToken?.throwIfCancelled();
        final retryable = policy.shouldRetryResponse(
          response,
          request,
          settings,
        );
        if (!retryable) {
          return response;
        }
        if (attempt >= settings.maxAttempts ||
            !budget.tryConsume(_budgetKey(request)) ||
            _isExhausted(startedAt, request)) {
          events?.onGiveUp?.call(
            RetryEvent(
              attempt: attempt,
              delay: Duration.zero,
              reason: RetryReason.status,
              statusCode: response.statusCode,
            ),
          );
          return response;
        }
        final parsed =
            retryAfterParser.parse(
              response.header('Retry-After'),
              now: clock.now().toUtc(),
            ) ??
            backoff.delayFor(attempt);
        // A server must not extend the retry budget past the configured bound.
        var delay = parsed > settings.maxDelay ? settings.maxDelay : parsed;
        final remaining = _remaining(startedAt, request);
        if (remaining != null && delay > remaining) {
          delay = remaining;
        }
        events?.onRetry?.call(
          RetryEvent(
            attempt: attempt,
            delay: delay,
            reason: RetryReason.status,
            statusCode: response.statusCode,
          ),
        );
        await _waitOrCancel(request, delay);
        request.throwIfDeadlineExceeded(clock.now().toUtc());
        if (_isExhausted(startedAt, request)) {
          events?.onGiveUp?.call(
            RetryEvent(
              attempt: attempt,
              delay: Duration.zero,
              reason: RetryReason.status,
              statusCode: response.statusCode,
            ),
          );
          return response;
        }
      } on Failure catch (failure) {
        request.cancelToken?.throwIfCancelled();
        final retryable = policy.shouldRetryFailure(failure, request);
        if (!retryable) {
          rethrow;
        }
        if (attempt >= settings.maxAttempts ||
            !budget.tryConsume(_budgetKey(request)) ||
            _isExhausted(startedAt, request)) {
          events?.onGiveUp?.call(
            RetryEvent(
              attempt: attempt,
              delay: Duration.zero,
              reason: RetryReason.failure,
              failure: failure,
            ),
          );
          rethrow;
        }
        var delay = backoff.delayFor(attempt);
        final remaining = _remaining(startedAt, request);
        if (remaining != null && delay > remaining) {
          delay = remaining;
        }
        events?.onRetry?.call(
          RetryEvent(
            attempt: attempt,
            delay: delay,
            reason: RetryReason.failure,
            failure: failure,
          ),
        );
        await _waitOrCancel(request, delay);
        request.throwIfDeadlineExceeded(clock.now().toUtc());
        if (_isExhausted(startedAt, request)) {
          events?.onGiveUp?.call(
            RetryEvent(
              attempt: attempt,
              delay: Duration.zero,
              reason: RetryReason.failure,
              failure: failure,
            ),
          );
          rethrow;
        }
      }
    }
  }

  String _budgetKey(HttpRequest request) {
    final uri = request.resolvedUri;
    if (uri.host.isNotEmpty) {
      return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    }
    return uri.path;
  }

  /// Time left before the request deadline or [HttpRetrySettings.totalBudget],
  /// whichever is stricter. Null when neither bound is configured.
  Duration? _remaining(DateTime startedAt, HttpRequest request) {
    final now = clock.now().toUtc();
    final deadlineRemaining = request.remainingUntil(now);
    final total = settings.totalBudget;
    final budgetRemaining = total == null
        ? null
        : total - now.difference(startedAt);
    if (deadlineRemaining == null) {
      if (budgetRemaining == null) {
        return null;
      }
      return budgetRemaining.isNegative ? Duration.zero : budgetRemaining;
    }
    if (budgetRemaining == null) {
      return deadlineRemaining;
    }
    final bounded = budgetRemaining.isNegative
        ? Duration.zero
        : budgetRemaining;
    return deadlineRemaining < bounded ? deadlineRemaining : bounded;
  }

  bool _isExhausted(DateTime startedAt, HttpRequest request) {
    final remaining = _remaining(startedAt, request);
    return remaining != null && remaining <= Duration.zero;
  }

  Future<void> _waitOrCancel(HttpRequest request, Duration delay) async {
    request.cancelToken?.throwIfCancelled();
    final cancelled = Completer<void>();
    final remove = request.cancelToken?.onCancel(() {
      if (!cancelled.isCompleted) cancelled.complete();
    });
    Timer? timer;
    try {
      final injectedDelay = _delay;
      final Future<void> waiting;
      if (injectedDelay != null) {
        waiting = injectedDelay(delay);
      } else {
        final elapsed = Completer<void>();
        timer = Timer(delay, elapsed.complete);
        waiting = elapsed.future;
      }
      await Future.any<void>([waiting, cancelled.future]);
      request.cancelToken?.throwIfCancelled();
    } finally {
      timer?.cancel();
      remove?.call();
    }
  }
}
