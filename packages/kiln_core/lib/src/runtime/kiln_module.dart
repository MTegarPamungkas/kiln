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

  void register(Registry registry);

  FutureOr<void> ready(Registry registry) {}

  FutureOr<void> dispose() {}
}
