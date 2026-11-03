import 'package:kiln_core/kiln_core.dart';

import 'idempotency.dart';
import 'retry_settings.dart';

/// Decides which responses and failures are worth retrying.
final class RetryPolicy {
  const RetryPolicy({this.idempotency = const Idempotency()});

  final Idempotency idempotency;

  bool shouldRetryResponse(
    HttpResponse response,
    HttpRequest request,
    HttpRetrySettings settings,
  ) {
    return idempotency.isIdempotent(request) &&
        settings.retryableStatusCodes.contains(response.statusCode);
  }

  bool shouldRetryFailure(Failure failure, HttpRequest request) {
    return failure.isRetryable && idempotency.isIdempotent(request);
  }
}
