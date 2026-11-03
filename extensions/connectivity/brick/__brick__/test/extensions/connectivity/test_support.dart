import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_config.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_gateway.dart';
import 'package:{{app_name}}/extensions/connectivity/device_network_monitor.dart';

final class FakeConnectivityGateway implements ConnectivityGateway {
  FakeConnectivityGateway({this.current = NetworkStatus.unknown});

  NetworkStatus current;
  Object? checkError;
  final StreamController<NetworkStatus> controller =
      StreamController<NetworkStatus>.broadcast(sync: true);

  @override
  Future<NetworkStatus> check() async {
    final error = checkError;
    if (error != null) {
      throw error;
    }
    return current;
  }

  @override
  Stream<NetworkStatus> get changes => controller.stream;

  void emit(NetworkStatus status) {
    current = status;
    controller.add(status);
  }

  Future<void> dispose() => controller.close();
}

DeviceNetworkMonitor createTestMonitor(FakeConnectivityGateway gateway) {
  return DeviceNetworkMonitor(
    gateway: gateway,
    config: const ConnectivityConfig(debounceWindow: Duration.zero),
  );
}
