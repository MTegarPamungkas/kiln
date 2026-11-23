import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/theme/theme_mode_controller.dart';
import 'package:{{app_name}}/extensions/theme/theme_mode_store.dart';

final class _DelayedStorage implements Storage {
  final Completer<Map<String, String>> gate =
      Completer<Map<String, String>>();
  final Map<String, String> values = <String, String>{};
  final reads = <Completer<String?>>[];
  bool failWrites = false;

  @override
  Future<String?> read(String key) async {
    if (reads.isNotEmpty) return reads.removeAt(0).future;
    final loaded = await gate.future;
    return loaded[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('storage unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<Set<String>> keys() async => values.keys.toSet();

  @override
  Future<void> clear() async {
    values.clear();
  }
}

void main() {
  test('an older load cannot overwrite a newer load', () async {
    final first = Completer<String?>();
    final second = Completer<String?>();
    final storage = _DelayedStorage()..reads.addAll([first, second]);
    final controller = ThemeModeController(store: ThemeModeStore(storage: storage));
    addTearDown(controller.dispose);
    final old = controller.load();
    final recent = controller.load();
    second.complete('dark');
    await recent;
    first.complete('light');
    await old;
    expect(controller.mode, ThemeMode.dark);
  });

  test('persistence failures do not reject selection or poison later writes', () async {
    final storage = _DelayedStorage()..failWrites = true;
    final controller = ThemeModeController(store: ThemeModeStore(storage: storage));
    addTearDown(controller.dispose);
    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);
    storage.failWrites = false;
    await controller.setMode(ThemeMode.light);
    expect(storage.values[ThemeModeStore.defaultKey], 'light');
  });
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

  test('setMode reports whether the choice is durable', () async {
    final storage = _DelayedStorage();
    final controller = ThemeModeController(
      store: ThemeModeStore(storage: storage),
    );
    addTearDown(controller.dispose);

    expect(await controller.setMode(ThemeMode.dark), PersistOutcome.persisted);
    storage.failWrites = true;
    expect(await controller.setMode(ThemeMode.light), PersistOutcome.sessionOnly);
    expect(controller.mode, ThemeMode.light);
  });

  test('setMode reports notConfigured when there is no storage', () async {
    final controller = ThemeModeController();
    addTearDown(controller.dispose);

    expect(await controller.setMode(ThemeMode.dark), PersistOutcome.notConfigured);
    expect(controller.mode, ThemeMode.dark);
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

  test('a load that finishes after dispose does not touch the notifier', () async {
    final storage = _DelayedStorage();
    final controller = ThemeModeController(
      store: ThemeModeStore(storage: storage),
    );
    var notified = false;
    controller.modeListenable.addListener(() => notified = true);

    final loading = controller.load();
    controller.dispose();
    storage.gate.complete(<String, String>{
      ThemeModeStore.defaultKey: 'dark',
    });
    await loading;

    expect(notified, isFalse);
    expect(controller.mode, ThemeMode.system);
  });

  test('dispose ignores later updates', () async {
    final storage = InMemoryStorage();
    final controller = ThemeModeController(
      store: ThemeModeStore(storage: storage),
    );

    controller.dispose();
    controller.dispose();
    await controller.setMode(ThemeMode.dark);
    await controller.load();

    expect(storage.snapshot, isEmpty);
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
