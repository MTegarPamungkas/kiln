import 'package:kiln_core/kiln_core.dart';

enum RetryReason { status, failure }

/// One retry attempt or give-up event.
final class RetryEvent {
  const RetryEvent({
    required this.attempt,
    required this.delay,
    required this.reason,
    this.statusCode,
    this.failure,
  });

  final int attempt;
  final Duration delay;
  final RetryReason reason;
  final int? statusCode;
  final Failure? failure;
}

/// Callbacks for observing retry decisions.
final class RetryEvents {
  const RetryEvents({this.onRetry, this.onGiveUp});

  final void Function(RetryEvent event)? onRetry;
  final void Function(RetryEvent event)? onGiveUp;
}
