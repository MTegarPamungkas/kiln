import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/l10n/l10n_config.dart';
import 'package:full_stack/extensions/l10n/locale_controller.dart';
import 'package:full_stack/extensions/l10n/locale_store.dart';

void main() {
  group('LocaleController', () {
    test('starts by following the system locale', () {
      final controller = LocaleController();
      addTearDown(controller.dispose);

      expect(controller.locale, isNull);
      expect(controller.localeListenable.value, isNull);
      expect(controller.localeNotifier, isA<ValueNotifier<Locale?>>());
    });

    test('notifies listeners when the locale changes', () async {
      final controller = LocaleController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.localeListenable.addListener(() => notifications++);

      await controller.setLocale(const Locale('en'));

      expect(controller.locale, const Locale('en'));
      expect(notifications, 1);

      await controller.followSystem();

      expect(controller.locale, isNull);
      expect(notifications, 2);
    });

    test('canonicalizes regional locales', () async {
      final controller = LocaleController();
      addTearDown(controller.dispose);

      await controller.setLocale(const Locale('id', 'ID'));

      expect(controller.locale, const Locale('id'));
    });

    test('rejects unsupported locales', () async {
      final controller = LocaleController();
      addTearDown(controller.dispose);

      await expectLater(
        controller.setLocale(const Locale('fr')),
        throwsArgumentError,
      );
      expect(controller.locale, isNull);
    });

    test('restores a persisted locale through the store', () async {
      final store = LocaleStore(InMemoryStorage());
      final controller = LocaleController(store: store);
      addTearDown(controller.dispose);
      await store.save(const Locale('en'));

      await controller.load();

      expect(controller.locale, const Locale('en'));
    });

    test('ignores unsupported persisted locales', () async {
      final storage = InMemoryStorage(<String, String>{
        LocaleStore.defaultKey: 'fr',
      });
      final controller = LocaleController(store: LocaleStore(storage));
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.locale, isNull);
    });

    test(
      'persists the selection and clears it when following system',
      () async {
        final storage = InMemoryStorage();
        final store = LocaleStore(storage);
        final controller = LocaleController(store: store);
        addTearDown(controller.dispose);

        await controller.setLocale(const Locale('en'));
        expect(await store.readOrNull(), const Locale('en'));

        await controller.followSystem();
        expect(await store.readOrNull(), isNull);
        expect(storage.snapshot, isEmpty);
      },
    );

    test('works without storage', () async {
      final controller = LocaleController(
        config: const L10nConfig(
          supportedLocales: <Locale>[Locale('en')],
          fallbackLocale: Locale('en'),
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.setLocale(const Locale('en'));

      expect(controller.locale, const Locale('en'));
    });
  });
}
