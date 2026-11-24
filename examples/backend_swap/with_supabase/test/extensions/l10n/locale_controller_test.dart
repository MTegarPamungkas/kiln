import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:with_supabase/extensions/l10n/l10n_config.dart';
import 'package:with_supabase/extensions/l10n/locale_controller.dart';
import 'package:with_supabase/extensions/l10n/locale_store.dart';

void main() {
  group('LocaleController', () {
    test('an older load cannot overwrite a newer load', () async {
      final first = Completer<String?>();
      final second = Completer<String?>();
      final storage = _ControlledStorage()..reads.addAll([first, second]);
      final controller = LocaleController(store: LocaleStore(storage));
      addTearDown(controller.dispose);
      final old = controller.load();
      final recent = controller.load();
      second.complete('en');
      await recent;
      first.complete('id');
      await old;
      expect(controller.locale, const Locale('en'));
    });

    test('a failed preference write does not poison later selections', () async {
      final storage = _ControlledStorage()..failWrites = true;
      final controller = LocaleController(store: LocaleStore(storage));
      addTearDown(controller.dispose);
      await controller.setLocale(const Locale('en'));
      expect(controller.locale, const Locale('en'));
      storage.failWrites = false;
      await controller.setLocale(const Locale('id'));
      expect(storage.values[LocaleStore.defaultKey], 'id');
    });
    test('setLocale reports whether the choice is durable', () async {
      final storage = _ControlledStorage();
      final controller = LocaleController(store: LocaleStore(storage));
      addTearDown(controller.dispose);

      expect(
        await controller.setLocale(const Locale('en')),
        PersistOutcome.persisted,
      );
      storage.failWrites = true;
      expect(
        await controller.setLocale(const Locale('id')),
        PersistOutcome.sessionOnly,
      );
      expect(controller.locale, const Locale('id'));
    });

    test('setLocale reports notConfigured without storage', () async {
      final controller = LocaleController();
      addTearDown(controller.dispose);

      expect(
        await controller.setLocale(const Locale('en')),
        PersistOutcome.notConfigured,
      );
    });

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

    test('dispose ignores later changes', () async {
      final storage = InMemoryStorage();
      final controller = LocaleController(store: LocaleStore(storage));

      controller.dispose();
      controller.dispose();
      await controller.setLocale(const Locale('en'));
      await controller.followSystem();

      expect(controller.locale, isNull);
      expect(storage.snapshot, isEmpty);
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

    test('persists the selection and clears it when following system', () async {
      final storage = InMemoryStorage();
      final store = LocaleStore(storage);
      final controller = LocaleController(store: store);
      addTearDown(controller.dispose);

      await controller.setLocale(const Locale('en'));
      expect(await store.readOrNull(), const Locale('en'));

      await controller.followSystem();
      expect(await store.readOrNull(), isNull);
      expect(storage.snapshot, isEmpty);
    });

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

final class _ControlledStorage implements Storage {
  final reads = <Completer<String?>>[];
  final values = <String, String>{};
  bool failWrites = false;

  @override
  Future<String?> read(String key) async => reads.isEmpty
      ? values[key] : await reads.removeAt(0).future;
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('storage unavailable');
    values[key] = value;
  }
  @override
  Future<void> delete(String key) async { values.remove(key); }
  @override
  Future<void> clear() async { values.clear(); }
  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
  @override
  Future<Set<String>> keys() async => values.keys.toSet();
}
