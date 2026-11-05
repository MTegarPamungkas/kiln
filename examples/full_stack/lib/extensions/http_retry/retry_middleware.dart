import 'package:kiln_core/kiln_core.dart';

import 'backoff.dart';
import 'retry_after_parser.dart';
import 'retry_budget.dart';
import 'retry_events.dart';
import 'retry_policy.dart';
import 'retry_settings.dart';

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
  }) : budget = budget ?? RetryBudget(),
       backoff = backoff ?? Backoff(settings: settings),
       _delay = delay ?? Future<void>.delayed;

  final HttpRetrySettings settings;
  final RetryPolicy policy;
  final RetryBudget budget;
  final RetryEvents? events;
  final Backoff backoff;
  final RetryAfterParser retryAfterParser;
  final Future<void> Function(Duration delay) _delay;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await next(request);
        final retryable = policy.shouldRetryResponse(
          response,
          request,
          settings,
        );
        if (!retryable) {
          return response;
        }
        if (attempt >= settings.maxAttempts ||
            !budget.tryConsume(request.resolvedUri.path)) {
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
        final delay =
            retryAfterParser.parse(
              response.header('Retry-After'),
              now: DateTime.now().toUtc(),
            ) ??
            backoff.delayFor(attempt);
        events?.onRetry?.call(
          RetryEvent(
            attempt: attempt,
            delay: delay,
            reason: RetryReason.status,
            statusCode: response.statusCode,
          ),
        );
        await _delay(delay);
      } on Failure catch (failure) {
        final retryable = policy.shouldRetryFailure(failure, request);
        if (!retryable) {
          rethrow;
        }
        if (attempt >= settings.maxAttempts ||
            !budget.tryConsume(request.resolvedUri.path)) {
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
        final delay = backoff.delayFor(attempt);
        events?.onRetry?.call(
          RetryEvent(
            attempt: attempt,
            delay: delay,
            reason: RetryReason.failure,
            failure: failure,
          ),
        );
        await _delay(delay);
      }
    }
  }
}
