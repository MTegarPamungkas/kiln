import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('ConsentController', () {
    test('is opt-in by default', () {
      final controller = ConsentController();

      expect(controller.isGranted(ConsentCategory.analytics), isFalse);
      expect(controller.isGranted(ConsentCategory.crashReports), isFalse);
      expect(controller.hasAnyConsent, isFalse);
    });

    test('grant and deny update one category and emit it', () async {
      final controller = ConsentController();
      final changes = <ConsentCategory>[];
      final subscription = controller.changes.listen(changes.add);

      controller.grant(ConsentCategory.analytics);
      expect(controller.isGranted(ConsentCategory.analytics), isTrue);
      expect(controller.hasAnyConsent, isTrue);

      controller.deny(ConsentCategory.analytics);
      expect(controller.isGranted(ConsentCategory.analytics), isFalse);

      expect(changes, [ConsentCategory.analytics, ConsentCategory.analytics]);
      await subscription.cancel();
      await controller.dispose();
    });

    test('setting the current value does not emit', () async {
      final controller = ConsentController(analytics: true);
      final changes = <ConsentCategory>[];
      final subscription = controller.changes.listen(changes.add);

      controller.set(ConsentCategory.analytics, true);
      controller.set(ConsentCategory.crashReports, false);

      expect(changes, isEmpty);
      await subscription.cancel();
      await controller.dispose();
    });

    test('reset revokes every category', () async {
      final controller = ConsentController(analytics: true, crashReports: true);

      controller.reset();

      expect(controller.decisions.values.every((granted) => !granted), isTrue);
      expect(controller.hasAnyConsent, isFalse);
      await controller.dispose();
    });

    test('decisions cannot be mutated from outside', () {
      final controller = ConsentController(analytics: true);

      expect(
        () => controller.decisions[ConsentCategory.analytics] = false,
        throwsUnsupportedError,
      );
    });
  });
}
