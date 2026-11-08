import 'package:sentry_flutter/sentry_flutter.dart';

import 'crash_report_config.dart';
import 'crash_report_gateway.dart';

/// [CrashReportGateway] backed by the `sentry_flutter` plugin.
///
/// This is the only file in the extension that touches the Sentry SDK, so the
/// rest of the reporter chain stays testable without a platform channel. Tests
/// replace this class with a fake gateway.
final class SdkSentryCrashGateway implements CrashReportGateway {
  SdkSentryCrashGateway();

  @override
  Future<void> init(CrashReportConfig config, {String? environment}) async {
    config.validate();
    await Sentry.init((options) {
      options.dsn = config.dsn;
      options.environment = environment ?? config.environment;
      final release = config.release.trim();
      if (release.isNotEmpty) {
        options.release = release;
      }
      options.sampleRate = config.sampleRate;
      options.sendDefaultPii = config.sendDefaultPii;
    });
  }

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) => _applyContext(scope, context),
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    await Sentry.captureMessage(
      message,
      withScope: (scope) => _applyContext(scope, context),
    );
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: 'app',
        level: SentryLevel.info,
        data: data,
      ),
    );
  }

  @override
  Future<void> setUser(String? userId) async {
    Sentry.configureScope(
      (scope) => scope.setUser(userId == null ? null : SentryUser(id: userId)),
    );
  }

  @override
  Future<void> setContext(String key, Map<String, Object?> value) async {
    Sentry.configureScope((scope) => scope.setContexts(key, value));
  }

  @override
  Future<void> flush() async {
    // Sentry v10 has no standalone flush; it flushes on capture and on close().
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> close() async {
    await Sentry.close();
  }

  void _applyContext(Scope scope, Map<String, Object?> context) {
    for (final entry in context.entries) {
      scope.setContexts(entry.key, entry.value);
    }
  }
}
