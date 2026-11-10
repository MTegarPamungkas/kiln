import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_config.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_gateway.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_module.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_support.dart';
import 'package:{{app_name}}/extensions/connectivity/device_network_monitor.dart';
import 'package:{{app_name}}/extensions/connectivity/reconnect_trigger.dart';

final class _FakeGateway implements ConnectivityGateway {
  _FakeGateway() {
    controller = StreamController<NetworkStatus>.broadcast(
      onCancel: () => cancelled = true,
    );
  }

  late final StreamController<NetworkStatus> controller;
  bool cancelled = false;

  @override
  Future<NetworkStatus> check() async => NetworkStatus.online;

  @override
  Stream<NetworkStatus> get changes => controller.stream;

  Future<void> close() => controller.close();
}

void main() {
  test('module stops its owned monitor on dispose', () async {
    final gateway = _FakeGateway();
    final registry = GetItRegistry();
    final module = ConnectivityModule(gatewayFactory: () => gateway);
    module.register(registry);
    await module.ready(registry);

    await module.dispose();
    expect(gateway.cancelled, isTrue);
    await gateway.close();
  });

  test('module registers NetworkMonitor and config', () {
    final registry = GetItRegistry();

    ConnectivityModule().register(registry);

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

    ConnectivityModule().register(registry);

    final monitor = registry.read<DeviceNetworkMonitor>();
    expect(monitor.reconnectTrigger, same(trigger));
    expect(monitor.client, same(client));
  });

  test('module adds the offline guard when a pipeline exists', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<HttpPipeline>(HttpPipeline());

    ConnectivityModule().register(registry);

    expect(registry.read<HttpPipeline>().middleware, hasLength(1));
  });
}
