import 'dart:async';

/// Service locator used by modules, extensions, and application code.
///
/// Prefer the typed contract (`read<AuthRepository>()`) over a concrete
/// implementation. A missing registration is a programming error and throws.
abstract interface class Registry {
  bool get isReady;

  bool isRegistered<T extends Object>({String? instanceName});

  T read<T extends Object>({String? instanceName});

  T? readOrNull<T extends Object>({String? instanceName});

  void registerSingleton<T extends Object>(T instance, {String? instanceName});

  /// Registers [instance] and makes the registry its owner.
  ///
  /// The registry runs [dispose], or `instance.dispose()` when the instance is a
  /// [Disposable] and no callback is given, once on [dispose] in reverse
  /// registration order. Use this for resources the registry created or owns;
  /// do not use it for an instance a module already disposes.
  void registerOwned<T extends Object>(
    T instance, {
    String? instanceName,
    FutureOr<void> Function()? dispose,
  });

  /// Runs owned disposal callbacks once, then clears every registration.
  ///
  /// Idempotent. Every callback is attempted even when one throws; the first
  /// error is rethrown afterwards. A registration made with [registerSingleton]
  /// is not disposed automatically, because its owner is the caller.
  Future<void> dispose();

  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
  });

  void registerFactory<T extends Object>(
    T Function() factory, {
    String? instanceName,
  });
  void unregister<T extends Object>({String? instanceName});
}
