import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/theme/theme_mode_store.dart';

void main() {
  test('round-trips every theme mode through storage', () async {
    final storage = InMemoryStorage();
    final store = ThemeModeStore(storage: storage);

    for (final mode in ThemeMode.values) {
      await store.write(mode);
      expect(await store.read(), mode);
      expect(storage.snapshot.containsKey(ThemeModeStore.defaultKey), isTrue);
    }
  });

  test('stores the mode under a custom key', () async {
    final storage = InMemoryStorage();
    final store = ThemeModeStore(storage: storage, key: 'app.theme');

    await store.write(ThemeMode.light);

    expect(storage.snapshot['app.theme'], 'light');
    expect(await store.read(), ThemeMode.light);
  });

  test('without storage it is a safe no-op', () async {
    final store = ThemeModeStore();

    expect(store.canPersist, isFalse);
    expect(await store.read(), isNull);
    await store.write(ThemeMode.dark);
    expect(await store.read(), isNull);
  });

  test('encodes and decodes known values only', () {
    expect(ThemeModeStore.encode(ThemeMode.system), 'system');
    expect(ThemeModeStore.encode(ThemeMode.light), 'light');
    expect(ThemeModeStore.encode(ThemeMode.dark), 'dark');
    expect(ThemeModeStore.decode('dark'), ThemeMode.dark);
    expect(ThemeModeStore.decode('sepia'), isNull);
    expect(ThemeModeStore.decode(null), isNull);
  });
}
