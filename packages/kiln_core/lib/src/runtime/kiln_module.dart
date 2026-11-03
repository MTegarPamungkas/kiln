import 'dart:async';

import 'registry.dart';

/// A unit of application wiring.
///
/// [provides] and [requires] are capability names, never extension ids.
/// Extend this class so the optional hooks keep their defaults.
abstract class KilnModule {
  const KilnModule();

  String get id;

  Set<String> get provides => const <String>{};

  Set<String> get requires => const <String>{};

  Set<String> get optionalRequires => const <String>{};

  /// Platforms this module supports. Empty means every platform.
  ///
  /// `KilnBootstrap` skips a module when the current platform is not listed,
  /// so a plugin that has no web implementation can stay installed while the
  /// web build simply does not register it.
  Set<String> get platforms => const <String>{};

  bool supportsPlatform(String platform) =>
      platforms.isEmpty || platforms.contains(platform);

  void register(Registry registry);

  FutureOr<void> ready(Registry registry) {}

  FutureOr<void> dispose() {}
}
