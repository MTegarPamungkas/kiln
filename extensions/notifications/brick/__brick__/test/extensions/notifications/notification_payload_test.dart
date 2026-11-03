import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/notifications/notification_payload.dart';

void main() {
  test('round trips a route and its arguments', () {
    const payload = NotificationPayload(
      route: '/orders/42',
      arguments: <String, Object?>{'tab': 'items', 'count': 2},
    );

    final decoded = NotificationPayload.tryDecode(payload.encode());

    expect(decoded, isNotNull);
    expect(decoded!.route, '/orders/42');
    expect(decoded.arguments, <String, Object?>{'tab': 'items', 'count': 2});
  });

  test('omits an empty argument map', () {
    const payload = NotificationPayload(route: '/home');

    expect(payload.encode(), '{"route":"/home"}');
    expect(NotificationPayload.tryDecode('{"args":{"x":1}}')!.route, isNull);
  });

  test('returns null for absent or malformed payloads', () {
    expect(NotificationPayload.tryDecode(null), isNull);
    expect(NotificationPayload.tryDecode(''), isNull);
    expect(NotificationPayload.tryDecode('not json'), isNull);
    expect(NotificationPayload.tryDecode('[1,2]'), isNull);
  });

  test('rejects payloads above the size limit', () {
    final payload = NotificationPayload(
      route: '/home',
      arguments: <String, Object?>{'blob': 'x' * NotificationPayload.maxEncodedLength},
    );

    expect(
      payload.encode,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
  });
}
