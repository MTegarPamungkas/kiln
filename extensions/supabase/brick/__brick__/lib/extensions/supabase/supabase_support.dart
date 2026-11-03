import 'package:kiln_core/kiln_core.dart';

import 'supabase_config.dart';

typedef SupabaseLoadProbe = Future<void> Function();

/// Validates configuration and prepares the Supabase client during bootstrap.
///
/// A missing or invalid URL/key is reported as `notConfigured`; a client that
/// cannot be created is `unavailable`. The anon key is never copied into the
/// support details.
final class SupabaseSupport {
  SupabaseSupport({required this.config, required this.probe});

  final SupabaseConfig config;
  final SupabaseLoadProbe probe;
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
    try {
      await probe();
      final uri = Uri.tryParse(config.url);
      return SupportInfo.supported(
        details: <String, Object?>{'host': uri?.host, 'schema': config.schema},
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
        message: 'Supabase client could not start: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
