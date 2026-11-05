import 'package:kiln_core/kiln_core.dart';

import 'neon_config.dart';

typedef NeonReachabilityProbe = Future<void> Function();

/// Validates the Neon Data API configuration during bootstrap.
///
/// A missing or invalid URL/token is reported as `notConfigured`. An optional
/// [probe] can reach the Data API once to prove it is answering; when it is
/// omitted the support check stays offline and only validates configuration.
/// The bearer token never appears in the support details.
final class NeonSupport {
  NeonSupport({required this.config, this.probe});

  final NeonConfig config;
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
    if (reachability == null) {
      final uri = Uri.tryParse(config.dataApiUrl);
      return SupportInfo.supported(
        details: <String, Object?>{
          'host': uri?.host,
          'schema': config.schema,
          'insecure_http': config.isInsecureTransport,
        },
      );
    }
    try {
      await reachability();
      final uri = Uri.tryParse(config.dataApiUrl);
      return SupportInfo.supported(
        details: <String, Object?>{
          'host': uri?.host,
          'schema': config.schema,
          'insecure_http': config.isInsecureTransport,
        },
      );
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
}
