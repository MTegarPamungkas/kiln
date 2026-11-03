import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme_mode_store.dart';

/// Owns the live [ThemeMode] that `AppThemeConfig.modeListenable` exposes.
final class ThemeModeController {
  factory ThemeModeController({
    ThemeMode initialMode = ThemeMode.system,
    ThemeModeStore? store,
  }) {
    return ThemeModeController._(initialMode, store);
  }

  ThemeModeController._(ThemeMode initialMode, this._store)
    : _mode = ValueNotifier<ThemeMode>(initialMode);

  final ThemeModeStore? _store;
  final ValueNotifier<ThemeMode> _mode;

  /// Listenable handed to `AppThemeConfig` so `AppShell` rebuilds.
  ValueListenable<ThemeMode> get modeListenable => _mode;

  /// Current mode.
  ThemeMode get mode => _mode.value;

  /// Switches to [mode], notifies listeners, and persists best effort.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode.value != mode) {
      _mode.value = mode;
    }
    final store = _store;
    if (store != null) {
      await store.write(mode);
    }
  }

  /// Restores the stored mode when one is available.
  Future<void> load() async {
    final store = _store;
    if (store == null) {
      return;
    }
    final stored = await store.read();
    if (stored != null) {
      _mode.value = stored;
    }
  }

  /// Releases the notifier; the app registry keeps this controller alive for
  /// the process lifetime, tests may dispose it.
  void dispose() {
    _mode.dispose();
  }
}
