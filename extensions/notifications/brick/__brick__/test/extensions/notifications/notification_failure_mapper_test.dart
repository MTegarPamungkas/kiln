import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/notifications/notification_failure_mapper.dart';

void main() {
  test('maps plugin errors to a notification failure', () {
    final failure = mapNotificationError(StateError('plugin down'));

    expect(failure.code, FailureCode.notificationsUnavailable);
    expect(failure.kind, FailureKind.notification);
    expect(failure.cause, isA<StateError>());
  });

  test('keeps an existing Failure', () {
    const original = Failure(
      code: FailureCode.notificationsPermissionDenied,
      message: 'denied',
      kind: FailureKind.notification,
    );

    expect(mapNotificationError(original), same(original));
  });
}
