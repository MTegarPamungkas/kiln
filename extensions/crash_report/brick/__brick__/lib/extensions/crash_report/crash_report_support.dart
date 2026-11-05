import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'crash_report_config.dart';

typedef CrashReportSetupProbe = Future<void> Function();

/// Reports whether crash reporting can send for the current configuration.
final class CrashReportSupport {
  CrashReportSupport({
    required this.config,
    required this.flavor,
    required this.probe,
  });

  final CrashReportConfig config;
  final AppFlavor? flavor;
  final CrashReportSetupProbe probe;
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
    try {
      config.validate();
    } on Failure catch (failure) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: failure.message,
        details: <String, Object?>{'code': failure.code.value},
      );
    }
    if (!config.isActiveFor(flavor)) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: config.isNoop
            ? 'Crash reporting is disabled because the DSN is empty.'
            : 'Crash reporting is disabled for this flavor.',
        details: <String, Object?>{
          'noop': config.isNoop,
          'flavor': flavor?.name,
        },
      );
    }
    try {
      await probe();
      return SupportInfo.supported(
        details: <String, Object?>{
          'environment': config.environmentFor(flavor),
          'flavor': flavor?.name,
        },
      );
    } on MissingPluginException catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Sentry is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on UnsupportedError catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Sentry is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
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
        message: 'Sentry could not start: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
