import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/analytics/pii_scrubbing_analytics.dart';

void main() {
  group('PiiScrubbingAnalytics', () {
    test('redacts sensitive properties before the delegate sees them', () async {
      final delegate = FakeAnalytics();
      final analytics = PiiScrubbingAnalytics(delegate: delegate);

      await analytics.capture(
        'signup failed',
        properties: <String, Object?>{
          'email': 'ada@example.com',
          'password': 'hunter2',
          'note': 'contact ada@example.com',
          'nested': <String, Object?>{
            'token': 'abc123',
            'plan': 'pro',
          },
          'contacts': <String>['ada@example.com', 'grace@example.com'],
        },
      );

      final properties = delegate.events.single.properties;
      expect(properties['email'], '[redacted]');
      expect(properties['password'], '[redacted]');
      expect(properties['note'], 'contact [redacted]');
      expect(properties['nested'], <String, Object?>{
        'token': '[redacted]',
        'plan': 'pro',
      });
      expect(properties['contacts'], <String>['[redacted]', '[redacted]']);
    });

    test('redacts identity traits but keeps the pseudonymous user id', () async {
      final delegate = FakeAnalytics();
      final analytics = PiiScrubbingAnalytics(delegate: delegate);

      await analytics.identify(
        'user-1',
        traits: <String, Object?>{
          'email': 'ada@example.com',
          'display_name': 'Ada',
          'access_token': 'secret-token',
        },
      );

      final identity = delegate.identities.single;
      expect(identity.userId, 'user-1');
      expect(identity.traits['email'], '[redacted]');
      expect(identity.traits['access_token'], '[redacted]');
      expect(identity.traits['display_name'], 'Ada');
    });

    test('leaves the caller properties untouched', () async {
      final delegate = FakeAnalytics();
      final analytics = PiiScrubbingAnalytics(delegate: delegate);
      final input = <String, Object?>{'email': 'ada@example.com'};

      await analytics.capture('signup failed', properties: input);

      expect(input['email'], 'ada@example.com');
    });

    test('reset passes through', () async {
      final delegate = FakeAnalytics();
      final analytics = PiiScrubbingAnalytics(delegate: delegate);

      await analytics.reset();

      expect(delegate.resetCalls, 1);
    });
  });
}
