import 'package:kiln_core/kiln_core.dart';

import 'neon_config.dart';
import 'neon_storage_config.dart';

typedef NeonReachabilityProbe = Future<void> Function();

/// Validates the Neon Data API (and, when configured, Object Storage) during
/// bootstrap.
///
/// A missing or invalid URL/token is reported as `notConfigured`. An optional
/// [probe] can reach the Data API once to prove it is answering; when it is
/// omitted the support check stays offline and only validates configuration.
/// Storage configuration is reported in the details but does not change the
/// Data API support state. Neither the bearer token nor the S3 secret appears
/// in the details.
final class NeonSupport {
  NeonSupport({required this.config, this.storageConfig, this.probe});

  final NeonConfig config;
  final NeonStorageConfig? storageConfig;
  final NeonReachabilityProbe? probe;
  SupportInfo? _last;

  Future<SupportInfo> check() async {
    final last = _last;
    if (last != null) {
      return last;
    }
    final info = await _probe();
    _last = info;
    return info;
  }

  void clear() => _last = null;

  Future<SupportInfo> _probe() async {
    final problem = config.validate();
    if (problem != null) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: problem.message,
        details: <String, Object?>{'code': problem.code.value},
      );
    }
    final reachability = probe;
    if (reachability != null) {
      try {
        await reachability();
      } on Failure catch (failure) {
        return SupportInfo.unsupported(
          failure.kind == FailureKind.configuration
              ? SupportState.notConfigured
              : SupportState.unavailable,
          message: failure.message,
          details: <String, Object?>{'code': failure.code.value},
        );
      } on Object catch (error) {
        return SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'The Neon Data API could not be reached: $error',
          details: <String, Object?>{'error': '$error'},
        );
      }
    }
    return SupportInfo.supported(details: _details());
  }

  Map<String, Object?> _details() {
    final uri = Uri.tryParse(config.dataApiUrl);
    final storage = storageConfig;
    return <String, Object?>{
      'host': uri?.host,
      'schema': config.schema,
      'insecure_http': config.isInsecureTransport,
      if (storage != null) ...{
        'storage_configured': storage.validate() == null,
        if (storage.validate() == null) 'storage_bucket': storage.bucket,
      },
    };
  }
}
