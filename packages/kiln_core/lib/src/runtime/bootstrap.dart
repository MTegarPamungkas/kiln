import 'dart:async';

import '../errors/failure.dart';
import '../errors/failure_codes.dart';
import '../gate/gate.dart';
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
    Set<String> requiredCapabilities = const <String>{},
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
    registry.registerSingleton<Gate>(Gate(registry));
    // Added first so reverse-order disposal runs it last, after modules have
    // released the resources they own.
    lifecycle.addDisposeCallback(registry.dispose);
    lifecycle
      ..addDisposeCallback(support.dispose)
      ..addDisposeCallback(slots.dispose)
      ..addDisposeCallback(consent.dispose)
      ..addDisposeCallback(session.dispose);

    try {
      for (final module in modules) {
        if (!module.supportsPlatform(activePlatform)) {
          if (module.requiredForStartup) {
            throw StateError(
              'Required module ${module.id} does not support '
              '$activePlatform.',
            );
          }
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
      final available = <String>{...capabilities};
      for (final module in ordered) {
        lifecycle.addDisposeCallback(module.dispose);
        module.register(registry);
        final missing = module.requires.difference(available);
        final info = missing.isEmpty
            ? await _probeSupport(module, registry, supportTimeout)
            : SupportInfo.unsupported(
                SupportState.unavailable,
                message:
                    '${module.id} requires unavailable capabilities: '
                    '${missing.join(', ')}.',
                details: <String, Object?>{
                  'missing_capabilities': missing.toList(),
                },
              );
        support.record(module.id, info);
        if (info.isSupported) {
          await Future<void>.sync(() => module.ready(registry))
              .timeout(timeout);
        }
        // ready() may downgrade support after an initialization failure.
        final effective = support[module.id] ?? info;
        if (effective.isSupported) {
          available.addAll(module.provides);
          onModuleReady?.call(module);
        } else if (module.requiredForStartup) {
          // A required module must stop startup with the typed reason instead of
          // leaving an invalid backend looking ready.
          throw effective.toFailure(
            message:
                'Required module ${module.id} is unavailable: '
                '${effective.message}',
          );
        }
      }
      final missingRequired = requiredCapabilities.difference(available);
      if (missingRequired.isNotEmpty) {
        throw Failure(
          code: FailureCode.unavailable,
          message:
              'Required startup capabilities are unavailable: '
              '${missingRequired.join(', ')}.',
          kind: FailureKind.unavailable,
          details: <String, Object?>{
            'missing_capabilities': missingRequired.toList(growable: false),
          },
        );
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
