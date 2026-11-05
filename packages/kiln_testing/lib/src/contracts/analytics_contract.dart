import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

/// Observable state a test needs from an [Analytics] implementation.
abstract interface class AnalyticsContractHarness {
  Analytics get analytics;

  int get eventCount;

  String? get lastEventName;

  Map<String, Object?> get lastEventProperties;

  int get identifyCount;

  String? get lastUserId;

  Map<String, Object?> get lastTraits;

  int get resetCount;
}

/// Behavior every [Analytics] implementation must share.
void analyticsContract({
  required AnalyticsContractHarness Function() create,
  String description = 'Analytics',
}) {
  group('$description contract', () {
    test('capture forwards the event name and properties', () async {
      final harness = create();

      await harness.analytics.capture(
        'signup',
        properties: const {'plan': 'pro'},
      );

      expect(harness.eventCount, 1);
      expect(harness.lastEventName, 'signup');
      expect(harness.lastEventProperties['plan'], 'pro');
    });

    test('identify forwards the user id and traits', () async {
      final harness = create();

      await harness.analytics.identify(
        'user-1',
        traits: const {'role': 'owner'},
      );

      expect(harness.identifyCount, 1);
      expect(harness.lastUserId, 'user-1');
      expect(harness.lastTraits['role'], 'owner');
    });

    test('reset clears identity', () async {
      final harness = create();

      await harness.analytics.reset();

      expect(harness.resetCount, 1);
    });
  });
}
