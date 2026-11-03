import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/theme/theme_mode_controller.dart';
import 'package:{{app_name}}/extensions/theme/theme_mode_store.dart';

void main() {
  test('setMode updates the mode and notifies listeners', () async {
    final controller = ThemeModeController();
    var notifications = 0;
    controller.modeListenable.addListener(() {
      notifications++;
    });

    expect(controller.mode, ThemeMode.system);
    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);
    expect(controller.modeListenable.value, ThemeMode.dark);
    expect(notifications, 1);

    await controller.setMode(ThemeMode.dark);
    expect(notifications, 1);

    await controller.setMode(ThemeMode.light);
    expect(notifications, 2);
  });

  test('setMode persists through the store', () async {
    final storage = InMemoryStorage();
    final controller = ThemeModeController(
      store: ThemeModeStore(storage: storage),
    );

    await controller.setMode(ThemeMode.light);

    expect(storage.snapshot[ThemeModeStore.defaultKey], 'light');
  });

  test('load restores the persisted mode', () async {
    final storage = InMemoryStorage(<String, String>{'theme.mode': 'dark'});
    final controller = ThemeModeController(
      store: ThemeModeStore(storage: storage),
    );

    await controller.load();

    expect(controller.mode, ThemeMode.dark);
  });

  test('load tolerates a missing store or value', () async {
    final withoutStore = ThemeModeController();
    await withoutStore.load();
    expect(withoutStore.mode, ThemeMode.system);

    final empty = ThemeModeController(store: ThemeModeStore());
    await empty.load();
    expect(empty.mode, ThemeMode.system);
  });
}
