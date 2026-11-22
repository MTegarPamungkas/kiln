import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'http_remote_config_gateway.dart';
import 'remote_config_cache.dart';
import 'remote_config_client.dart';
import 'remote_config_config.dart';
import 'remote_config_gateway.dart';
import 'remote_config_support.dart';

/// Registers [RemoteConfig] over an HTTP JSON endpoint.
///
/// The initial fetch+activate runs during [ready]; if it fails the extension
/// records a support state and keeps serving caller defaults, so the app still
/// boots. With the `storage` extension installed, every successful fetch is
/// persisted and a fresh last-known-good snapshot is served while the endpoint
/// is unreachable. An empty endpoint makes it a no-op source.
final class RemoteConfigModule extends KilnModule {
  RemoteConfigModule({
    RemoteConfigConfig? config,
    RemoteConfigGateway Function()? gatewayFactory,
  }) : _config = config ?? RemoteConfigConfig.defaults,
       _gatewayFactory = gatewayFactory ?? HttpRemoteConfigGateway.new;

  final RemoteConfigConfig _config;
  final RemoteConfigGateway Function() _gatewayFactory;
  RemoteConfigClient? _client;
  Future<void>? _initialFetch;
  StreamSubscription<LifecycleState>? _lifecycleSubscription;
  Clock _clock = const SystemClock();
  DateTime? _backgroundedAt;
  DateTime? _lastRefreshAt;
  bool _refreshing = false;
  bool _disposed = false;

  @override
  String get id => 'remote_config';

  @override
  Set<String> get provides => const <String>{'remote_config'};

  @override
  Set<String> get optionalRequires => const <String>{'flavor', 'storage'};

  @override
  void register(Registry registry) {
    final gateway = _gatewayFactory();
    _initialFetch = null;
    _clock = registry.readOrNull<Clock>() ?? const SystemClock();
    final storage = registry.readOrNull<Storage>();
    final client = RemoteConfigClient(
      config: _config,
      gateway: gateway,
      cache: storage == null
          ? null
          : StorageRemoteConfigCache(storage: storage),
    );
    _client = client;
    final flavor = registry.readOrNull<AppFlavor>();

    registry
      ..registerSingleton<RemoteConfigConfig>(_config)
      ..registerSingleton<RemoteConfigSupport>(
        RemoteConfigSupport(
          config: _config,
          flavor: flavor,
          probe: _probeReachable,
        ),
      )
      ..registerSingleton<RemoteConfigGateway>(gateway)
      ..registerSingleton<RemoteConfigClient>(client)
      ..registerSingleton<RemoteConfig>(client);
  }

  Future<void> _probeReachable() async {
    if (_config.isNoop) {
      return;
    }
    final client = _client!;
    final fetch = client.fetch();
    _initialFetch = fetch;
    try {
      await fetch;
    } on Object {
      // A fresh last-known-good snapshot keeps the extension usable offline.
      if (!await client.activateCached()) {
        rethrow;
      }
    }
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<RemoteConfigSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    final flavor = registry.readOrNull<AppFlavor>();
    if (!_config.isActiveFor(flavor)) {
      return;
    }
    final client = _client;
    if (client == null) return;
    // Serve the persisted values first so gating works without the network.
    final cached = await client.activateCached();
    try {
      // Support probing already fetched a validated pending snapshot.
      await (_initialFetch ?? client.fetch());
      // Bootstrap may have timed out and disposed this module while the fetch
      // was in flight; activating a closed client afterwards is invalid.
      if (_disposed) {
        return;
      }
      client.activate();
    } on Object catch (error) {
      if (_disposed) {
        return;
      }
      if (cached) {
        // The last-known-good values are active; the fetch is retried later.
        _watchLifecycle(registry);
        return;
      }
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Remote config could not load: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
      return;
    }
    _watchLifecycle(registry);
  }

  /// Refreshes on resume after the app stayed in the background for
  /// [RemoteConfigConfig.fetchInterval].
  ///
  /// Foreground-only: no OS background scheduling, so no native dependency.
  void _watchLifecycle(Registry registry) {
    if (!_config.refreshOnResume ||
        _config.isNoop ||
        _lifecycleSubscription != null) {
      return;
    }
    final lifecycle = registry.readOrNull<Lifecycle>();
    if (lifecycle == null) {
      return;
    }
    _lastRefreshAt = _clock.now();
    _lifecycleSubscription = lifecycle.changes.listen((state) {
      switch (state) {
        case LifecycleState.paused:
          _backgroundedAt = _clock.now();
        case LifecycleState.resumed:
          unawaited(_refreshIfDue());
        case LifecycleState.created:
        case LifecycleState.ready:
        case LifecycleState.disposed:
          break;
      }
    });
  }

  Future<void> _refreshIfDue() async {
    final client = _client;
    if (_disposed || _refreshing || client == null) {
      return;
    }
    final now = _clock.now();
    final backgroundedAt = _backgroundedAt;
    final last = _lastRefreshAt;
    _backgroundedAt = null;
    final awayLongEnough = backgroundedAt == null ||
        now.difference(backgroundedAt) >= _config.fetchInterval;
    final dueSinceLast =
        last == null || now.difference(last) >= _config.fetchInterval;
    if (!awayLongEnough || !dueSinceLast) {
      return;
    }
    _refreshing = true;
    try {
      await client.fetchAndActivate();
      _lastRefreshAt = _clock.now();
    } on Object {
      // A failed refresh keeps the active snapshot; the next resume retries.
    } finally {
      _refreshing = false;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final subscription = _lifecycleSubscription;
    _lifecycleSubscription = null;
    await subscription?.cancel();
    final client = _client;
    _client = null;
    _initialFetch = null;
    await client?.close();
  }
}
