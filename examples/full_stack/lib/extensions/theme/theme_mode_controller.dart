import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kiln_core/kiln_core.dart';

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
  bool _disposed = false;
  int _generation = 0;
  Future<void> _writes = Future<void>.value();

  /// Listenable handed to `AppThemeConfig` so `AppShell` rebuilds.
  ValueListenable<ThemeMode> get modeListenable => _mode;

  /// Current mode.
  ThemeMode get mode => _mode.value;

  /// Switches to [mode], notifies listeners, and persists best effort.
  ///
  /// Returns whether the choice is durable: [PersistOutcome.persisted] when it
  /// was saved, otherwise the mode still applies for this session.
  Future<PersistOutcome> setMode(ThemeMode mode) async {
    if (_disposed) {
      return PersistOutcome.notConfigured;
    }
    _generation++;
    if (_mode.value != mode) {
      _mode.value = mode;
    }
    final store = _store;
    if (store == null) {
      return PersistOutcome.notConfigured;
    }
    final write = _writes.then((_) => store.write(mode));
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }

  /// Restores the stored mode when one is available.
  Future<void> load() async {
    final store = _store;
    if (store == null || _disposed) {
      return;
    }
    final generation = ++_generation;
    final stored = await store.read();
    if (stored != null && !_disposed && generation == _generation) {
      _mode.value = stored;
    }
  }

  /// Releases the notifier; the app registry keeps this controller alive for
  /// the process lifetime, tests may dispose it.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _mode.dispose();
  }
}
