import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef PushTargetsContractFactory = FutureOr<PushTargets> Function();

/// Behavior every [PushTargets] implementation must share.
void pushTargetsContract({
  required PushTargetsContractFactory create,
  String description = 'PushTargets',
  String token = 'fcm-token-abc',
}) {
  group('$description contract', () {
    test('register stores the device token and returns the target', () async {
      final targets = await create();

      final target = await targets.register(token: token);

      expect(target.id, isNotEmpty);
      expect(target.identifier, token);
      expect(target.expired, isFalse);
    });

    test('registering again updates the target instead of duplicating it',
        () async {
      final targets = await create();

      final first = await targets.register(token: token);
      final second = await targets.register(token: 'fcm-token-rotated');

      expect(second.id, first.id);
      expect(second.identifier, 'fcm-token-rotated');
    });

    test('update replaces the token of an existing target', () async {
      final targets = await create();

      final target = await targets.register(token: token);
      final updated = await targets.update(
        targetId: target.id,
        token: 'fcm-token-new',
      );

      expect(updated.id, target.id);
      expect(updated.identifier, 'fcm-token-new');
    });

    test('unregister removes the target', () async {
      final targets = await create();

      final target = await targets.register(token: token);
      await targets.unregister(targetId: target.id);

      await expectLater(
        targets.update(targetId: target.id, token: token),
        throwsA(
          isA<Failure>().having(
            (value) => value.code,
            'code',
            FailureCode.pushTargetsNotFound,
          ),
        ),
      );
    });
  });
}
