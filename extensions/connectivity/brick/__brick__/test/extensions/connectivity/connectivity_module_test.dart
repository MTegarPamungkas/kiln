import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_config.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_module.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_support.dart';
import 'package:{{app_name}}/extensions/connectivity/device_network_monitor.dart';
import 'package:{{app_name}}/extensions/connectivity/reconnect_trigger.dart';

void main() {
  test('module registers NetworkMonitor and config', () {
    final registry = GetItRegistry();

    const ConnectivityModule().register(registry);

    expect(registry.read<NetworkMonitor>(), isA<NetworkMonitor>());
    expect(registry.read<DeviceNetworkMonitor>(), isA<DeviceNetworkMonitor>());
    expect(registry.read<ConnectivityConfig>().probeInterval, isNotNull);
    expect(registry.read<ConnectivitySupport>(), isA<ConnectivitySupport>());
  });

  test('module wires an optional ReconnectTrigger and HttpClient', () {
    final trigger = ReconnectTrigger(onReconnect: () {});
    final client = FakeHttpClient(
      defaultResponse: const HttpResponse(statusCode: 200),
    );
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<ReconnectTrigger>(trigger)
      ..registerSingleton<HttpClient>(client);

    const ConnectivityModule().register(registry);

    final monitor = registry.read<DeviceNetworkMonitor>();
    expect(monitor.reconnectTrigger, same(trigger));
    expect(monitor.client, same(client));
  });

  test('module adds the offline guard when a pipeline exists', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<HttpPipeline>(HttpPipeline());

    const ConnectivityModule().register(registry);

    expect(registry.read<HttpPipeline>().middleware, hasLength(1));
  });
}
