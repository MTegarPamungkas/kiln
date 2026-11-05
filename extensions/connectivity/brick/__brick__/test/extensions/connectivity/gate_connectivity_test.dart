import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_config.dart';
import 'package:{{app_name}}/extensions/connectivity/device_network_monitor.dart';
import 'package:{{app_name}}/extensions/connectivity/gate_connectivity.dart';

import 'test_support.dart';

Gate _gate(HttpClient? client, {String? probeUrl}) {
  final registry = GetItRegistry();
  final monitor = DeviceNetworkMonitor(
    gateway: FakeConnectivityGateway(),
    config: ConnectivityConfig(probeUrl: probeUrl),
    client: client,
  );
  registry
    ..registerSingleton<NetworkMonitor>(monitor)
    ..registerSingleton<DeviceNetworkMonitor>(monitor);
  return Gate(registry);
}

void main() {
  test('networkReachable is true when no probe is configured', () async {
    final gate = _gate(null);

    final result = await gate.networkReachable();

    expect(result.valueOrNull, isTrue);
  });

  test('networkReachable probes the configured url', () async {
    final client = FakeHttpClient(
      defaultResponse: const HttpResponse(statusCode: 200),
    );
    final gate = _gate(client, probeUrl: 'https://api.kiln.dev/health');

    final result = await gate.networkReachable();

    expect(result.valueOrNull, isTrue);
    expect(client.requests.single.method, HttpMethod.head);
  });

  test('networkReachable is false when the probe fails', () async {
    final client = FakeHttpClient(
      failure: const Failure(
        code: FailureCode.networkUnreachable,
        message: 'unreachable',
        kind: FailureKind.network,
      ),
    );
    final gate = _gate(client, probeUrl: 'https://api.kiln.dev/health');

    final result = await gate.networkReachable();

    expect(result.valueOrNull, isFalse);
  });
}
