import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_client.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_config.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_gateway.dart';

/// [RemoteConfigGateway] that returns staged values instead of hitting HTTP.
final class FakeRemoteConfigGateway implements RemoteConfigGateway {
  Map<String, Object?> remoteValues = <String, Object?>{};
  int loadCalls = 0;
  String? lastUrl;
  Duration? lastTimeout;
  Object? failure;

  @override
  Future<Map<String, Object?>> load(String url, {Duration? timeout}) async {
    loadCalls++;
    lastUrl = url;
    lastTimeout = timeout;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return Map<String, Object?>.from(remoteValues);
  }

  @override
  Future<void> close() async {}
}

/// [RemoteConfigContractHarness] over [RemoteConfigClient] and a fake gateway.
final class RemoteConfigHarness implements RemoteConfigContractHarness {
  RemoteConfigHarness()
    : gateway = FakeRemoteConfigGateway() {
    config = RemoteConfigClient(
      config: RemoteConfigConfig(endpoint: 'https://flags.test/config.json'),
      gateway: gateway,
    );
  }

  final FakeRemoteConfigGateway gateway;

  @override
  late final RemoteConfig config;

  @override
  void seedRemote(Map<String, Object?> values) {
    gateway.remoteValues = Map<String, Object?>.from(values);
  }

  @override
  void failFetch() => gateway.failure = StateError('endpoint down');
}
