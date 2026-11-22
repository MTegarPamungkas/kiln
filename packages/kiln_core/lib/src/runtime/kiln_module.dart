import 'dart:async';

import 'registry.dart';
import 'support.dart';

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

  /// Whether an unavailable support probe must abort application startup.
  ///
  /// Required modules stop bootstrap with the typed failure from their support
  /// state. Optional features keep the default graceful-degradation policy: the
  /// contracts stay registered, [ready] is skipped, and dependents that require
  /// a missing capability skip [ready] too. [Future.timeout] only bounds the
  /// wait; it cannot cancel a plugin call, so implementations must fence late
  /// results after disposal.
  bool get requiredForStartup => false;

  /// Platforms this module supports. Empty means every platform.
  ///
  /// `KilnBootstrap` skips a module when the current platform is not listed,
  /// so a plugin that has no web implementation can stay installed while the
  /// web build simply does not register it.
  Set<String> get platforms => const <String>{};

  bool supportsPlatform(String platform) =>
      platforms.isEmpty || platforms.contains(platform);

  void register(Registry registry);

  /// Probes platform and device support after [register].
  ///
  /// The result is recorded in `SupportRegistry`. When it is not supported,
  /// bootstrap skips [ready] so a missing sensor, plugin, or desktop service
  /// cannot block application startup. Modules should keep their contracts
  /// registered and return a typed support failure from calls that still run.
  FutureOr<SupportInfo> support(Registry registry) =>
      const SupportInfo.supported();

  FutureOr<void> ready(Registry registry) {}

  FutureOr<void> dispose() {}
}
