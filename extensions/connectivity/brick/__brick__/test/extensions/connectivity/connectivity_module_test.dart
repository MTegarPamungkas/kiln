import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_config.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_module.dart';

void main() {
  test('module registers NetworkMonitor and config', () {
    final registry = GetItRegistry();

    const ConnectivityModule().register(registry);

    expect(registry.read<NetworkMonitor>(), isA<NetworkMonitor>());
    expect(registry.read<ConnectivityConfig>().probeInterval, isNotNull);
  });

  test('module adds the offline guard when a pipeline exists', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<HttpPipeline>(HttpPipeline());

    const ConnectivityModule().register(registry);

    expect(registry.read<HttpPipeline>().middleware, hasLength(1));
  });
}
