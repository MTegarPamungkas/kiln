import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'analytics_config.dart';
import 'analytics_gateway.dart';
import 'analytics_support.dart';
import 'consent_gate_analytics.dart';
import 'noop_analytics.dart';
import 'pii_scrubbing_analytics.dart';
import 'posthog_analytics.dart';
import 'sdk_posthog_gateway.dart';
import 'session_identity_listener.dart';

/// Registers [Analytics] on top of PostHog.
///
/// The decorator order is [ConsentGateAnalytics] outermost, then
/// [PiiScrubbingAnalytics], then either [PosthogAnalytics] or
/// [NoopAnalytics]. Nothing reaches the SDK, and no property is scrubbed,
/// before analytics consent is granted.
final class AnalyticsModule extends KilnModule {
  AnalyticsModule({
    AnalyticsConfig? config,
    AnalyticsGateway Function()? gatewayFactory,
  }) : _config = config ?? AnalyticsConfig.defaults,
       _gatewayFactory = gatewayFactory ?? SdkPosthogGateway.new;

  final AnalyticsConfig _config;
  final AnalyticsGateway Function() _gatewayFactory;
  AnalyticsGateway? _gateway;
  SessionIdentityListener? _listener;
  AnalyticsSupport? _support;
  SupportRegistry? _supportRegistry;
  ConsentController? _consent;
  AppFlavor? _flavor;
  Registry? _registry;
  StreamSubscription<ConsentCategory>? _consentSubscription;
  Future<void>? _setup;
  Future<void> _consentWork = Future<void>.value();
  bool _disposed = false;
  bool _resetOnNextGrant = false;

  /// Completes when queued consent reactions have run.
  Future<void> get idle => _consentWork;

  bool get _consented =>
      !_disposed && (_consent?.isGranted(ConsentCategory.analytics) ?? false);

  @override
  String get id => 'analytics';

  @override
  Set<String> get provides => const <String>{'analytics'};

  @override
  Set<String> get optionalRequires => const <String>{'flavor'};

  @override
  void register(Registry registry) {
    final gateway = _gatewayFactory();
    _gateway = gateway;
    _registry = registry;
    final posthog = PosthogAnalytics(gateway: gateway);
    final flavor = registry.readOrNull<AppFlavor>();
    _flavor = flavor;
    final sends = _config.isActiveFor(flavor);
    final consent = registry.read<ConsentController>();
    _consent = consent;

    final Analytics base = sends ? posthog : const NoopAnalytics();
    final scrubbed = PiiScrubbingAnalytics(delegate: base);
    final analytics = ConsentGateAnalytics(
      delegate: scrubbed,
      consent: consent,
      isActive: () => !_disposed,
    );
    final listener = SessionIdentityListener(
      sessions: registry.read<SessionController>(),
      analytics: analytics,
    );
    _listener = listener;
    final support = AnalyticsSupport(
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
      ..registerSingleton<AnalyticsConfig>(_config)
      ..registerSingleton<AnalyticsSupport>(support)
      ..registerSingleton<Analytics>(analytics)
      ..registerSingleton<SessionIdentityListener>(listener);

    _consentSubscription = consent.changes.listen((category) {
      if (category != ConsentCategory.analytics) {
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
    if (setup == null) {
      return;
    }
    try {
      await setup;
    } on Object {
      return;
    }
    try {
      await _gateway?.setEnabled(false);
      // `reset()` rotates the identity, which also makes the native SDK reload
      // feature flags — a network request after consent was withdrawn. The
      // rotation is deferred to the next grant instead: nothing is queued while
      // revoked, and the new consent starts from a fresh identity.
      _resetOnNextGrant = true;
    } on Object {
      // Revocation is best-effort; sending is already gated in Dart.
    }
    _support?.clear();
    await _refreshSupport();
  }

  Future<void> _start() async {
    try {
      await _ensureSetup();
      if (!_consented) return;
      // `optOut()` persists in the SDK across launches, and setup() does not
      // clear it, so a session that starts after an earlier revoke would stay
      // silent. Opting in on every grant keeps the stored state aligned with
      // the current consent.
      if (_resetOnNextGrant) {
        _resetOnNextGrant = false;
        await _gateway?.reset();
      }
      await _gateway?.setEnabled(true);
      if (!_consented) {
        await _gateway?.setEnabled(false);
        _resetOnNextGrant = true;
      }
    } on Object catch (error) {
      _recordSetupError(error);
    }
    _support?.clear();
    if (_consented) {
      _listener?.syncCurrentSession();
    }
    await _refreshSupport();
  }

  /// Re-records the support state after a consent transition.
  ///
  /// `SupportRegistry` only holds the bootstrap-time snapshot; without this the
  /// app keeps seeing the pre-consent `notConfigured` even while events flow.
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
        message: 'Analytics could not start: $error',
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
        await gateway.setup(_config, isAllowed: () => _consented);
      } finally {
        // Disposal may have happened before the platform setup completed.
        if (_disposed) await _shutdown(gateway);
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
    return registry.read<AnalyticsSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    if (_disposed) return;
    _listener?.start();
    if (_consented && _config.isActiveFor(_flavor)) {
      await _start();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final gateway = _gateway;
    _gateway = null;
    _registry = null;
    final subscription = _consentSubscription;
    _consentSubscription = null;
    await subscription?.cancel();
    final listener = _listener;
    _listener = null;
    await listener?.dispose();
    if (_setup != null && gateway != null) {
      await _shutdown(gateway);
    }
  }

  Future<void> _shutdown(AnalyticsGateway gateway) async {
    // Try each privacy/cleanup operation even if another one fails.
    for (final operation in [
      () => gateway.setEnabled(false), gateway.reset, gateway.shutdown,
    ]) {
      try { await operation(); } on Object { /* Best-effort teardown. */ }
    }
  }
}
