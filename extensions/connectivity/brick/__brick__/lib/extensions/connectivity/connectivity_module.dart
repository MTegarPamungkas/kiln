import 'package:kiln_core/kiln_core.dart';

import 'connectivity_config.dart';
import 'connectivity_gateway.dart';
import 'device_network_monitor.dart';
import 'offline_guard_middleware.dart';

/// Registers the NetworkMonitor and optional offline guard.
final class ConnectivityModule extends KilnModule {
  const ConnectivityModule();

  @override
  String get id => 'connectivity';

  @override
  Set<String> get provides => const <String>{'connectivity'};

  @override
  Set<String> get optionalRequires => const <String>{'http_pipeline'};

  @override
  void register(Registry registry) {
    const config = ConnectivityConfig.defaults;
    final monitor = DeviceNetworkMonitor(
      gateway: ConnectivityPlusGateway(),
      config: config,
    );
    registry
      ..registerSingleton<ConnectivityConfig>(config)
      ..registerSingleton<NetworkMonitor>(monitor);

    final pipeline = registry.readOrNull<HttpPipeline>();
    if (pipeline != null) {
      pipeline.use(OfflineGuardMiddleware(monitor), priority: 5);
    }
  }

  @override
  Future<void> ready(Registry registry) async {
    final monitor = registry.read<NetworkMonitor>();
    if (monitor is DeviceNetworkMonitor) {
      try {
        await monitor.start();
      } on Object {
        // Connectivity can be unavailable on unsupported platforms.
      }
    }
  }
}
