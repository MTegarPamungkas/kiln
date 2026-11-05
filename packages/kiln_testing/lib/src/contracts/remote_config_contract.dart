import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

/// Observable state a test needs from a [RemoteConfig] implementation.
abstract interface class RemoteConfigContractHarness {
  RemoteConfig get config;

  /// Stage the values the next fetch should expose.
  void seedRemote(Map<String, Object?> values);

  /// Make the next [RemoteConfig.fetch] fail.
  void failFetch();
}

/// Behavior every [RemoteConfig] implementation must share.
void remoteConfigContract({
  required RemoteConfigContractHarness Function() create,
  String description = 'RemoteConfig',
}) {
  group('$description contract', () {
    test('typed getters fall back to caller defaults when unset', () {
      final harness = create();

      expect(harness.config.getBool('missing'), isFalse);
      expect(harness.config.getInt('missing'), 0);
      expect(harness.config.getDouble('missing'), 0);
      expect(harness.config.getString('missing'), '');
      expect(harness.config.getJson('missing'), isEmpty);
    });

    test('setDefaults provides fallbacks', () {
      final harness = create();
      harness.config.setDefaults(<String, Object?>{
        'on': true,
        'limit': 5,
      });

      expect(harness.config.getBool('on'), isTrue);
      expect(harness.config.getInt('limit'), 5);
    });

    test('fetch and activate exposes source values', () async {
      final harness = create();
      harness.seedRemote(<String, Object?>{
        'on': true,
        'limit': 9,
        'ratio': 1.5,
        'name': 'kilo',
        'cfg': <String, Object?>{'a': 1},
      });

      await harness.config.fetchAndActivate();

      expect(harness.config.getBool('on'), isTrue);
      expect(harness.config.getInt('limit'), 9);
      expect(harness.config.getDouble('ratio'), 1.5);
      expect(harness.config.getString('name'), 'kilo');
      expect(harness.config.getJson('cfg')['a'], 1);
    });

    test('active values override defaults', () async {
      final harness = create();
      harness.config.setDefaults(<String, Object?>{'name': 'fallback'});
      harness.seedRemote(<String, Object?>{'name': 'active'});

      await harness.config.fetchAndActivate();

      expect(harness.config.getString('name'), 'active');
    });

    test('changes emits after activation', () async {
      final harness = create();
      final firstChange = harness.config.changes.first;
      harness.seedRemote(<String, Object?>{'k': 1});

      await harness.config.fetchAndActivate();
      await firstChange;

      expect(harness.config.getInt('k'), 1);
    });

    test('a fetch failure leaves the active snapshot unchanged', () async {
      final harness = create();
      harness.seedRemote(<String, Object?>{'v': 1});
      await harness.config.fetchAndActivate();
      expect(harness.config.getInt('v'), 1);

      harness.failFetch();

      await expectLater(
        harness.config.fetch(),
        throwsA(isA<Object>()),
      );
      expect(harness.config.getInt('v'), 1);
    });
  });
}
