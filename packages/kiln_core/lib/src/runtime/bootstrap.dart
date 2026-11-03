import 'dart:async';

import '../privacy/consent.dart';
import '../session/session_controller.dart';
import '../util/clock.dart';
import 'get_it_registry.dart';
import 'kiln_module.dart';
import 'lifecycle.dart';
import 'module_graph.dart';
import 'registry.dart';
import 'slot.dart';

typedef BootstrapErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Runs module registration and readiness in dependency order.
abstract final class KilnBootstrap {
  static Future<Registry> run({
    required List<KilnModule> modules,
    Duration timeout = const Duration(seconds: 30),
    Clock? clock,
    BootstrapErrorHandler? onError,
    void Function(KilnModule module)? onModuleReady,
    Set<String> capabilities = const <String>{},
  }) async {
    final registry = GetItRegistry();
    final slots = SlotRegistry();
    final session = SessionController();
    final consent = ConsentController();
    final lifecycle = LifecycleController();

    registry.registerSingleton<SlotRegistry>(slots);
    registry.registerSingleton<SessionController>(session);
    registry.registerSingleton<ConsentController>(consent);
    registry.registerSingleton<LifecycleController>(lifecycle);
    registry.registerSingleton<Lifecycle>(lifecycle);
    registry.registerSingleton<Clock>(clock ?? const SystemClock());

    final ordered = ModuleGraph(modules)
        .resolve(availableCapabilities: capabilities);
    final registered = <KilnModule>[];

    try {
      for (final module in ordered) {
        module.register(registry);
        registered.add(module);
        await Future<void>.sync(() => module.ready(registry)).timeout(timeout);
        onModuleReady?.call(module);
      }
      await lifecycle.onReady();
      return registry;
    } catch (error, stackTrace) {
      for (final module in registered.reversed) {
        try {
          await Future<void>.sync(module.dispose);
        } catch (_) {
          // A failing dispose must not hide the original initialization error.
        }
      }
      await lifecycle.dispose();
      await session.dispose();
      await consent.dispose();
      await slots.dispose();
      if (onError != null) {
        onError(error, stackTrace);
      }
      rethrow;
    }
  }
}
