import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/analytics/posthog_analytics.dart';

import 'test_support.dart';

enum _Plan { free, pro }

void main() {
  group('PosthogAnalytics', () {
    test('capture forwards the sanitized event to the gateway', () async {
      final gateway = FakeAnalyticsGateway();
      final analytics = PosthogAnalytics(gateway: gateway);

      await analytics.capture(
        'project created',
        properties: <String, Object?>{
          'plan': _Plan.pro,
          'seats': 3,
          'trial': Duration(hours: 24),
          'created_at': DateTime.utc(2026, 1, 2, 3, 4, 5),
          'tags': <String>['a', 'b'],
          'meta': <String, Object?>{'source': 'invite', 'empty': null},
          'missing': null,
        },
      );

      expect(gateway.events, hasLength(1));
      expect(gateway.lastEvent?.name, 'project created');
      expect(gateway.lastEvent?.properties, <String, Object?>{
        'plan': 'pro',
        'seats': 3,
        'trial': 86400000,
        'created_at': '2026-01-02T03:04:05.000Z',
        'tags': <String>['a', 'b'],
        'meta': <String, Object?>{'source': 'invite'},
      });
    });

    test('identify forwards the sanitized traits and user id', () async {
      final gateway = FakeAnalyticsGateway();
      final analytics = PosthogAnalytics(gateway: gateway);

      await analytics.identify(
        'user-1',
        traits: <String, Object?>{'plan': _Plan.free, 'seats': 1},
      );

      expect(gateway.identities, hasLength(1));
      expect(gateway.lastIdentity?.userId, 'user-1');
      expect(gateway.lastIdentity?.traits, <String, Object?>{
        'plan': 'free',
        'seats': 1,
      });
    });

    test('reset and flush reach the gateway', () async {
      final gateway = FakeAnalyticsGateway();
      final analytics = PosthogAnalytics(gateway: gateway);

      await analytics.reset();
      await analytics.flush();

      expect(gateway.resetCalls, 1);
      expect(gateway.flushCalls, 1);
    });

    test('maps gateway errors to an unavailable Failure', () async {
      final gateway = FakeAnalyticsGateway()..failure = StateError('offline');
      final analytics = PosthogAnalytics(gateway: gateway);

      await expectLater(
        analytics.capture('project created'),
        throwsA(
          isA<Failure>()
              .having((failure) => failure.code, 'code', FailureCode.unavailable)
              .having(
                (failure) => failure.kind,
                'kind',
                FailureKind.unavailable,
              )
              .having((failure) => failure.cause, 'cause', isA<StateError>()),
        ),
      );
    });

    test('rejects properties the sanitizer cannot represent', () async {
      final gateway = FakeAnalyticsGateway();
      final analytics = PosthogAnalytics(gateway: gateway);

      await expectLater(
        analytics.capture('project created', properties: <String, Object?>{
          'callback': Object(),
        }),
        throwsA(
          isA<Failure>()
              .having(
                (failure) => failure.code,
                'code',
                FailureCode.validationUnsupportedValue,
              )
              .having(
                (failure) => failure.kind,
                'kind',
                FailureKind.validation,
              ),
        ),
      );
      expect(gateway.events, isEmpty);
    });

    test('rejects an empty event name', () async {
      final analytics = PosthogAnalytics(gateway: FakeAnalyticsGateway());

      await expectLater(
        analytics.capture('  '),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.kind,
            'kind',
            FailureKind.validation,
          ),
        ),
      );
    });
  });
}
