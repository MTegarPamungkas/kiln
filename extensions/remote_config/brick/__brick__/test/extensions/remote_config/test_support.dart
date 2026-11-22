import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_cache.dart';
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
  Completer<void>? loadGate;
  int closeCalls = 0;

  @override
  Future<Map<String, Object?>> load(String url, {Duration? timeout}) async {
    loadCalls++;
    lastUrl = url;
    lastTimeout = timeout;
    await loadGate?.future;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return Map<String, Object?>.from(remoteValues);
  }

  @override
  Future<void> close() async {
    closeCalls++;
  }
}

/// [RemoteConfigContractHarness] over [RemoteConfigClient] and a fake gateway.
final class RemoteConfigHarness implements RemoteConfigContractHarness {
  RemoteConfigHarness() : gateway = FakeRemoteConfigGateway() {
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

/// [RemoteConfigCache] staged in memory for client and module tests.
final class FakeRemoteConfigCache implements RemoteConfigCache {
  FakeRemoteConfigCache({
    this.snapshot,
    this.failSave = false,
    this.failLoad = false,
  });

  RemoteConfigSnapshot? snapshot;
  bool failSave;
  bool failLoad;
  int saves = 0;
  int loads = 0;

  @override
  Future<void> save(RemoteConfigSnapshot snapshot) async {
    saves++;
    if (failSave) {
      throw StateError('cache write failed');
    }
    this.snapshot = snapshot;
  }

  @override
  Future<RemoteConfigSnapshot?> load() async {
    loads++;
    if (failLoad) {
      throw StateError('cache read failed');
    }
    return snapshot;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}
