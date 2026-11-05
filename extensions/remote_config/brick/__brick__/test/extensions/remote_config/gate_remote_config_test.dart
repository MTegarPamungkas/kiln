import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/remote_config/gate_remote_config.dart';

void main() {
  group('GateRemoteConfigX', () {
    late FakeRemoteConfig fake;
    late Gate gate;

    setUp(() {
      fake = FakeRemoteConfig();
      final registry = GetItRegistry()
        ..registerSingleton<RemoteConfig>(fake);
      gate = Gate(registry);
    });

    test('featureEnabled reads the active boolean', () async {
      fake.seedRemote(<String, Object?>{'beta': true});
      await fake.fetchAndActivate();

      expect(gate.featureEnabled('beta'), isTrue);
      expect(gate.featureEnabled('nope', defaultValue: false), isFalse);
    });

    test('typed reads forward to the active snapshot', () async {
      fake.seedRemote(<String, Object?>{'limit': 7, 'name': 'kiln'});
      await fake.fetchAndActivate();

      expect(gate.remoteConfigInt('limit'), 7);
      expect(gate.remoteConfigString('name'), 'kiln');
    });

    test('setRemoteDefaults registers defaults', () {
      gate.setRemoteDefaults(<String, Object?>{'x': true});

      expect(fake.getBool('x'), isTrue);
    });

    test('fetchRemoteConfig returns Ok', () async {
      final result = await gate.fetchRemoteConfig();

      expect(result, isA<Ok<void>>());
    });

    test('remoteConfigChanges emits after activation', () async {
      final firstChange = gate.remoteConfigChanges.first;
      fake.seedRemote(<String, Object?>{'k': 1});

      await fake.fetchAndActivate();
      await firstChange;

      expect(gate.remoteConfigInt('k'), 1);
    });
  });
}
