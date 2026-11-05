import 'package:kiln_core/kiln_core.dart';

import 'http_remote_config_gateway.dart';
import 'remote_config_client.dart';
import 'remote_config_config.dart';
import 'remote_config_gateway.dart';
import 'remote_config_support.dart';

/// Registers [RemoteConfig] over an HTTP JSON endpoint.
///
/// The initial fetch+activate runs during [ready]; if it fails the extension
/// records a support state and keeps serving caller defaults, so the app still
/// boots. An empty endpoint makes it a no-op source.
final class RemoteConfigModule extends KilnModule {
  RemoteConfigModule({
    RemoteConfigConfig? config,
    RemoteConfigGateway Function()? gatewayFactory,
  }) : _config = config ?? RemoteConfigConfig.defaults,
       _gatewayFactory = gatewayFactory ?? HttpRemoteConfigGateway.new;

  final RemoteConfigConfig _config;
  final RemoteConfigGateway Function() _gatewayFactory;
  RemoteConfigGateway? _gateway;
  RemoteConfigClient? _client;

  @override
  String get id => 'remote_config';

  @override
  Set<String> get provides => const <String>{'remote_config'};

  @override
  Set<String> get optionalRequires => const <String>{'flavor'};

  @override
  void register(Registry registry) {
    final gateway = _gatewayFactory();
    _gateway = gateway;
    final client = RemoteConfigClient(config: _config, gateway: gateway);
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
    await _gateway!.load(_config.endpoint, timeout: _config.requestTimeout);
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
    try {
      await _client!.fetchAndActivate();
    } on Object catch (error) {
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Remote config could not load: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    final client = _client;
    _client = null;
    _gateway = null;
    await client?.close();
  }
}
