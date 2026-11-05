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
