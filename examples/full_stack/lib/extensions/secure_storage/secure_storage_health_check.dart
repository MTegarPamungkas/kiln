import 'package:kiln_core/kiln_core.dart';

/// Probes a SecureStorage with a write-read-delete cycle.
final class SecureStorageHealthCheck {
  const SecureStorageHealthCheck({this.probeKey = 'health_check_probe'});

  final String probeKey;

  Future<bool> run(SecureStorage storage, {AppLogger? logger}) async {
    const value = 'ok';
    try {
      await storage.write(probeKey, value);
      final read = await storage.read(probeKey);
      await storage.delete(probeKey);
      final healthy = read == value;
      if (logger != null) {
        if (healthy) {
          logger.info('Secure storage health check passed');
        } else {
          logger.warning('Secure storage health check returned a wrong value');
        }
      }
      return healthy;
    } catch (error, stackTrace) {
      logger?.error(
        'Secure storage health check failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
