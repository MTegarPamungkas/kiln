import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:with_supabase/extensions/l10n/locale_store.dart';

void main() {
  group('LocaleStore', () {
    test('returns null when nothing is stored', () async {
      final store = LocaleStore(InMemoryStorage());

      expect(await store.readOrNull(), isNull);
    });

    test('saves and reads a locale', () async {
      final storage = InMemoryStorage();
      final store = LocaleStore(storage);

      await store.save(const Locale('en'));

      expect(await store.readOrNull(), const Locale('en'));
      expect(storage.snapshot, <String, String>{LocaleStore.defaultKey: 'en'});
    });

    test('round-trips a regional locale', () async {
      final store = LocaleStore(InMemoryStorage());

      await store.save(const Locale('en', 'US'));

      expect(await store.readOrNull(), const Locale('en', 'US'));
    });

    test('clears the key for the system locale', () async {
      final storage = InMemoryStorage();
      final store = LocaleStore(storage);
      await store.save(const Locale('en'));

      await store.save(null);

      expect(await store.readOrNull(), isNull);
      expect(storage.snapshot, isEmpty);
    });

    test('ignores invalid stored tags', () async {
      final storage = InMemoryStorage(<String, String>{
        LocaleStore.defaultKey: 'not a locale!',
      });
      final store = LocaleStore(storage);

      expect(await store.readOrNull(), isNull);
    });

    test('uses a custom key when provided', () async {
      final storage = InMemoryStorage();
      final store = LocaleStore(storage, key: 'custom.locale');

      await store.save(const Locale('id'));

      expect(storage.snapshot, <String, String>{'custom.locale': 'id'});
      expect(await store.readOrNull(), const Locale('id'));
    });
  });
}
