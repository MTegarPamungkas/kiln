import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/analytics/consent_gate_analytics.dart';

void main() {
  group('ConsentGateAnalytics', () {
    test('sends nothing before analytics consent is granted', () async {
      final delegate = FakeAnalytics();
      final consent = ConsentController();
      final analytics = ConsentGateAnalytics(
        delegate: delegate,
        consent: consent,
      );

      await analytics.capture('project created');
      await analytics.identify('user-1', traits: const {'role': 'owner'});

      expect(delegate.events, isEmpty);
      expect(delegate.identities, isEmpty);
    });

    test('does not accept other consent categories', () async {
      final delegate = FakeAnalytics();
      final consent = ConsentController(crashReports: true);
      final analytics = ConsentGateAnalytics(
        delegate: delegate,
        consent: consent,
      );

      await analytics.capture('project created');

      expect(delegate.events, isEmpty);
    });

    test('starts sending when consent is granted later', () async {
      final delegate = FakeAnalytics();
      final consent = ConsentController();
      final analytics = ConsentGateAnalytics(
        delegate: delegate,
        consent: consent,
      );

      await analytics.capture('before consent');
      consent.grant(ConsentCategory.analytics);
      await analytics.capture('after consent');
      await analytics.identify('user-1');

      expect(delegate.events.map((event) => event.name), <String>[
        'after consent',
      ]);
      expect(delegate.identities, hasLength(1));
    });

    test('stops sending when consent is withdrawn', () async {
      final delegate = FakeAnalytics();
      final consent = ConsentController(analytics: true);
      final analytics = ConsentGateAnalytics(
        delegate: delegate,
        consent: consent,
      );

      await analytics.capture('first');
      consent.deny(ConsentCategory.analytics);
      await analytics.capture('second');

      expect(delegate.events.map((event) => event.name), <String>['first']);
    });

    test('reset is forwarded so stored identity is cleared', () async {
      final delegate = FakeAnalytics();
      final analytics = ConsentGateAnalytics(
        delegate: delegate,
        consent: ConsentController(),
      );

      await analytics.reset();

      expect(delegate.resetCalls, 1);
    });
  });
}
