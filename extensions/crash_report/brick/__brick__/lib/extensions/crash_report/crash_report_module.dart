import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'consent_gate_crash_reporter.dart';
import 'crash_report_config.dart';
import 'crash_report_gateway.dart';
import 'crash_report_support.dart';
import 'error_deduplicator.dart';
import 'http_breadcrumb_middleware.dart';
import 'noop_crash_reporter.dart';
import 'pii_scrubbing_crash_reporter.dart';
import 'safe_crash_reporter.dart';
import 'sentry_crash_gateway.dart';
import 'sentry_crash_reporter.dart';

/// Registers [CrashReporter] on top of Sentry.
///
/// The decorator order is [SafeCrashReporter] outermost, then
/// [ConsentGateCrashReporter], then [PiiScrubbingCrashReporter], then
/// [ErrorDeduplicator], then either [SentryCrashReporter] or
/// [NoopCrashReporter]. Reporting never throws, nothing leaves the device before
/// crash-report consent, nothing is sent unredacted, and repeated identical
/// errors collapse to one within a window. When the `http_pipeline` capability is
/// present, [HttpBreadcrumbMiddleware] records each exchange as a breadcrumb.
final class CrashReportModule extends KilnModule {
  CrashReportModule({
    CrashReportConfig? config,
    CrashReportGateway Function()? gatewayFactory,
  }) : _config = config ?? CrashReportConfig.defaults,
       _gatewayFactory = gatewayFactory ?? SdkSentryCrashGateway.new;

  final CrashReportConfig _config;
  final CrashReportGateway Function() _gatewayFactory;
  CrashReportGateway? _gateway;
  AppFlavor? _flavor;
  ConsentController? _consent;
  CrashReportSupport? _support;
  SupportRegistry? _supportRegistry;
  Registry? _registry;
  StreamSubscription<ConsentCategory>? _consentSubscription;
  Future<void>? _setup;
  Future<void> _consentWork = Future<void>.value();
  bool _disposed = false;

  /// Completes when queued consent reactions have run.
  Future<void> get idle => _consentWork;

  bool get _consented =>
      !_disposed && (_consent?.isGranted(ConsentCategory.crashReports) ?? false);

  @override
  String get id => 'crash_report';

  @override
  Set<String> get provides => const <String>{'crash_reporter'};

  @override
  Set<String> get optionalRequires =>
      const <String>{'flavor', 'http_pipeline'};

  @override
  void register(Registry registry) {
    final gateway = _gatewayFactory();
    _gateway = gateway;
    _registry = registry;
    final sentry = SentryCrashReporter(gateway: gateway);
    final flavor = registry.readOrNull<AppFlavor>();
    _flavor = flavor;
    final sends = _config.isActiveFor(flavor);
    final clock = registry.readOrNull<Clock>() ?? const SystemClock();
    final consent = registry.read<ConsentController>();
    _consent = consent;

    final CrashReporter inner = sends ? sentry : const NoopCrashReporter();
    final deduped = ErrorDeduplicator(
      delegate: inner,
      clock: clock,
      window: _config.dedupWindow,
      enabled: _config.dedupEnabled,
    );
    final scrubbed = PiiScrubbingCrashReporter(delegate: deduped);
    final consented = ConsentGateCrashReporter(
      delegate: scrubbed,
      consent: consent,
      isActive: () => !_disposed,
    );
    final reporter = SafeCrashReporter(
      delegate: consented,
      logger: registry.readOrNull<AppLogger>(),
    );
    final support = CrashReportSupport(
      config: _config,
      flavor: flavor,
      probe: _ensureSetup,
      isAllowed: () => _consented,
    );
    _support = support;
    _supportRegistry = registry.readOrNull<SupportRegistry>();

    // The gateway and the concrete reporter stay private: exposing them would
    // let a caller bypass the consent and redaction decorators.
    registry
      ..registerSingleton<CrashReportConfig>(_config)
      ..registerSingleton<CrashReportSupport>(support)
      ..registerSingleton<CrashReporter>(reporter);

    final httpPipeline = registry.readOrNull<HttpPipeline>();
    if (httpPipeline != null && _config.httpBreadcrumbsEnabled) {
      httpPipeline.use(
        HttpBreadcrumbMiddleware(reporter: reporter, clock: clock),
        priority: HttpBreadcrumbMiddleware.priority,
      );
    }

    _consentSubscription = consent.changes.listen((category) {
      if (category != ConsentCategory.crashReports) {
        return;
      }
      _consentWork = _consentWork.then((_) => _onConsentChanged());
    });
  }

  Future<void> _onConsentChanged() async {
    if (_disposed || !_config.isActiveFor(_flavor)) {
      return;
    }
    if (_consented) {
      await _start();
      return;
    }
    final setup = _setup;
    if (setup != null) {
      try {
        await setup;
      } on Object {
        return;
      }
    }
    try {
      // Queued and automatic events are dropped by the gateway's consent
      // filter; clearing the identity prevents later association.
      await _gateway?.setUser(null);
    } on Object {
      // Revocation is best-effort; Dart-level consent gating still applies.
    }
    _support?.clear();
    await _refreshSupport();
  }

  Future<void> _start() async {
    try {
      await _ensureSetup();
    } on Object catch (error) {
      _recordSetupError(error);
    }
    _support?.clear();
    await _refreshSupport();
  }

  /// Re-records the support state after a consent transition.
  ///
  /// `SupportRegistry` only holds the bootstrap-time snapshot; without this the
  /// app keeps seeing the pre-consent `notConfigured` even while reports flow.
  /// The probe is memoized in [_ensureSetup], so this never re-runs SDK setup.
  Future<void> _refreshSupport() async {
    final support = _support;
    final target = _supportRegistry;
    if (_disposed || support == null || target == null) {
      return;
    }
    try {
      target.record(id, await support.check());
    } on Object {
      // Support reporting must never break a consent transition.
    }
  }

  void _recordSetupError(Object error) {
    if (_disposed) return;
    _registry?.readOrNull<SupportRegistry>()?.record(
      id,
      SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Sentry could not start: $error',
        details: <String, Object?>{'error': '$error'},
      ),
    );
  }

  Future<void> _ensureSetup() async {
    if (!_consented) {
      return;
    }
    final gateway = _gateway;
    if (gateway == null) {
      return;
    }
    final existing = _setup;
    if (existing != null) {
      await existing;
      return;
    }
    final future = () async {
      try {
        await gateway.init(_config,
          environment: _config.environmentFor(_flavor),
          isAllowed: () => _consented);
      } finally {
        if (_disposed) {
          try { await gateway.close(); } on Object { /* Best-effort teardown. */ }
        }
      }
    }();
    _setup = future;
    try {
      await future;
    } catch (_) {
      _setup = null;
      rethrow;
    }
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<CrashReportSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    if (_disposed) return;
    if (_consented && _config.isActiveFor(_flavor)) {
      await _start();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _registry = null;
    final subscription = _consentSubscription;
    _consentSubscription = null;
    await subscription?.cancel();
    final gateway = _gateway;
    _gateway = null;
    _setup = null;
    if (gateway == null) {
      return;
    }
    try {
      await gateway.close();
    } on Object {
      // Shutdown errors are ignored; the app is already going away.
    }
  }
}
