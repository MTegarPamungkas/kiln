import 'package:kiln_core/kiln_core.dart';

/// Fails fast with a network Failure while the device is offline.
final class OfflineGuardMiddleware implements HttpMiddleware {
  const OfflineGuardMiddleware(this.monitor);

  final NetworkMonitor monitor;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    if (monitor.status == NetworkStatus.offline) {
      throw const Failure(
        code: FailureCode.networkOffline,
        message: 'The device is offline',
        kind: FailureKind.network,
        isRetryable: true,
      );
    }
    return next(request);
  }
}
