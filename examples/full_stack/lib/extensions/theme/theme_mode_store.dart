import 'package:material_ui/material_ui.dart';
import 'package:kiln_core/kiln_core.dart';

/// Persists the selected [ThemeMode] through the optional [Storage] contract.
///
/// The store is usable without storage: reads return null and writes are
/// ignored, so the theme still works in apps that install no storage
/// extension.
final class ThemeModeStore {
  factory ThemeModeStore({Storage? storage, String key = defaultKey}) {
    return ThemeModeStore._(storage, key);
  }

  const ThemeModeStore._(this._storage, this.key);

  /// Storage key used when the caller does not override it.
  static const String defaultKey = 'theme.mode';

  final Storage? _storage;

  /// Storage key that holds the mode name.
  final String key;

  /// Whether a [Storage] contract is available.
  bool get canPersist => _storage != null;

  /// Reads the stored mode, tolerating a missing or unreadable value.
  Future<ThemeMode?> read() async {
    final storage = _storage;
    if (storage == null) {
      return null;
    }
    try {
      return decode(await storage.read(key));
    } on Object {
      return null;
    }
  }

  /// Writes [mode] and reports whether it is durable.
  ///
  /// A storage failure never blocks switching the theme: the mode still applies
  /// for this session and the caller is told it will not survive a restart.
  Future<PersistOutcome> write(ThemeMode mode) async {
    final storage = _storage;
    if (storage == null) {
      return PersistOutcome.notConfigured;
    }
    try {
      await storage.write(key, encode(mode));
      return PersistOutcome.persisted;
    } on Object {
      return PersistOutcome.sessionOnly;
    }
  }

  /// Serializes [mode] into the value kept in storage.
  static String encode(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
  };

  /// Parses a stored value; unknown values return null.
  static ThemeMode? decode(String? value) => switch (value) {
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => null,
  };
}
