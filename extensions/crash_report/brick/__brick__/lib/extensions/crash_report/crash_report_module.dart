import 'package:kiln_core/kiln_core.dart';

import 'consent_gate_crash_reporter.dart';
import 'crash_report_config.dart';
import 'crash_report_gateway.dart';
import 'crash_report_support.dart';
import 'noop_crash_reporter.dart';
import 'pii_scrubbing_crash_reporter.dart';
import 'safe_crash_reporter.dart';
import 'sentry_crash_gateway.dart';
import 'sentry_crash_reporter.dart';

/// Registers [CrashReporter] on top of Sentry.
///
/// The decorator order is [SafeCrashReporter] outermost, then
/// [ConsentGateCrashReporter], then [PiiScrubbingCrashReporter], then either
/// [SentryCrashReporter] or [NoopCrashReporter]. Reporting never throws, nothing
/// leaves the device before crash-report consent, and nothing is sent unredacted.
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
  Future<void>? _setup;

  @override
  String get id => 'crash_report';

  @override
  Set<String> get provides => const <String>{'crash_reporter'};

  @override
  Set<String> get optionalRequires => const <String>{'flavor'};

  @override
  void register(Registry registry) {
    final gateway = _gatewayFactory();
    _gateway = gateway;
    final sentry = SentryCrashReporter(gateway: gateway);
    final flavor = registry.readOrNull<AppFlavor>();
    _flavor = flavor;
    final sends = _config.isActiveFor(flavor);

    final CrashReporter base = sends ? sentry : const NoopCrashReporter();
    final scrubbed = PiiScrubbingCrashReporter(delegate: base);
    final consented = ConsentGateCrashReporter(
      delegate: scrubbed,
      consent: registry.read<ConsentController>(),
    );
    final reporter = SafeCrashReporter(
      delegate: consented,
      logger: registry.readOrNull<AppLogger>(),
    );

    registry
      ..registerSingleton<CrashReportConfig>(_config)
      ..registerSingleton<CrashReportSupport>(
        CrashReportSupport(
          config: _config,
          flavor: flavor,
          probe: _ensureSetup,
        ),
      )
      ..registerSingleton<CrashReportGateway>(gateway)
      ..registerSingleton<SentryCrashReporter>(sentry)
      ..registerSingleton<CrashReporter>(reporter);
  }

  Future<void> _ensureSetup() {
    return _setup ??= _gateway!.init(
      _config,
      environment: _config.environmentFor(_flavor),
    );
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<CrashReportSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    final flavor = registry.readOrNull<AppFlavor>();
    if (_config.isActiveFor(flavor)) {
      try {
        await _ensureSetup();
      } on Object catch (error) {
        registry.readOrNull<SupportRegistry>()?.record(
          id,
          SupportInfo.unsupported(
            SupportState.unavailable,
            message: 'Sentry could not start: $error',
            details: <String, Object?>{'error': '$error'},
          ),
        );
      }
    }
  }

  @override
  Future<void> dispose() async {
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
