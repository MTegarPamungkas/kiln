import 'dart:async';

import '../privacy/consent.dart';
import '../session/session_controller.dart';
import '../util/clock.dart';
import 'get_it_registry.dart';
import 'kiln_module.dart';
import 'lifecycle.dart';
import 'module_graph.dart';
import 'platform/platform.dart';
import 'registry.dart';
import 'slot.dart';
import 'support.dart';

typedef BootstrapErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Runs module registration and readiness in dependency order.
abstract final class KilnBootstrap {
  static Future<Registry> run({
    required List<KilnModule> modules,
    Duration timeout = const Duration(seconds: 30),
    Duration supportTimeout = const Duration(seconds: 5),
    Clock? clock,
    BootstrapErrorHandler? onError,
    void Function(KilnModule module)? onModuleReady,
    Set<String> capabilities = const <String>{},
    String? platform,
  }) async {
    final registry = GetItRegistry();
    final slots = SlotRegistry();
    final session = SessionController();
    final consent = ConsentController();
    final lifecycle = LifecycleController();
    final support = SupportRegistry();
    final activePlatform = platform ?? currentPlatform;

    registry.registerSingleton<SlotRegistry>(slots);
    registry.registerSingleton<SessionController>(session);
    registry.registerSingleton<ConsentController>(consent);
    registry.registerSingleton<LifecycleController>(lifecycle);
    registry.registerSingleton<Lifecycle>(lifecycle);
    registry.registerSingleton<Clock>(clock ?? const SystemClock());
    registry.registerSingleton<SupportRegistry>(support);
    lifecycle
      ..addDisposeCallback(support.dispose)
      ..addDisposeCallback(slots.dispose)
      ..addDisposeCallback(consent.dispose)
      ..addDisposeCallback(session.dispose);

    try {
      for (final module in modules) {
        if (!module.supportsPlatform(activePlatform)) {
          support.record(
            module.id,
            SupportInfo.unsupported(
              SupportState.unsupportedPlatform,
              message: '${module.id} is not supported on $activePlatform.',
              details: <String, Object?>{
                'platform': activePlatform,
                'supported_platforms': module.platforms.toList(growable: false),
              },
            ),
          );
        }
      }

      final ordered = ModuleGraph(
        modules
            .where((module) => module.supportsPlatform(activePlatform))
            .toList(growable: false),
      ).resolve(availableCapabilities: capabilities);
      for (final module in ordered) {
        lifecycle.addDisposeCallback(module.dispose);
        module.register(registry);
        final info = await _probeSupport(module, registry, supportTimeout);
        support.record(module.id, info);
        if (info.isSupported) {
          await Future<void>.sync(() => module.ready(registry))
              .timeout(timeout);
        }
        onModuleReady?.call(module);
      }
      await lifecycle.onReady();
      return registry;
    } catch (error, stackTrace) {
      try {
        await lifecycle.dispose();
      } catch (_) {
        // Cleanup must not hide the original initialization error.
      }
      try {
        onError?.call(error, stackTrace);
      } finally {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  static Future<SupportInfo> _probeSupport(
    KilnModule module,
    Registry registry,
    Duration timeout,
  ) async {
    try {
      return await Future<SupportInfo>.sync(() => module.support(registry))
          .timeout(timeout);
    } on TimeoutException {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: '${module.id} support probe timed out.',
        details: <String, Object?>{'timeout_ms': timeout.inMilliseconds},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: '${module.id} support probe failed: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
