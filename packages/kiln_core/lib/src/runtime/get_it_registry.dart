import 'package:get_it/get_it.dart';

import 'registry.dart';

/// [Registry] backed by a private get_it container.
final class GetItRegistry implements Registry {
  GetItRegistry({GetIt? getIt}) : _getIt = getIt ?? GetIt.asNewInstance();

  final GetIt _getIt;

  @override
  bool get isReady => true;

  @override
  bool isRegistered<T extends Object>({String? instanceName}) =>
      _getIt.isRegistered<T>(instanceName: instanceName);

  @override
  T read<T extends Object>({String? instanceName}) =>
      _getIt<T>(instanceName: instanceName);

  @override
  T? readOrNull<T extends Object>({String? instanceName}) =>
      _getIt.isRegistered<T>(instanceName: instanceName)
      ? _getIt<T>(instanceName: instanceName)
      : null;

  @override
  void registerSingleton<T extends Object>(T instance, {String? instanceName}) {
    _getIt.registerSingleton<T>(instance, instanceName: instanceName);
  }

  @override
  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    _getIt.registerLazySingleton<T>(factory, instanceName: instanceName);
  }

  @override
  void registerFactory<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    _getIt.registerFactory<T>(factory, instanceName: instanceName);
  }

  @override
  void unregister<T extends Object>({String? instanceName}) {
    _getIt.unregister<T>(instanceName: instanceName);
  }
}
