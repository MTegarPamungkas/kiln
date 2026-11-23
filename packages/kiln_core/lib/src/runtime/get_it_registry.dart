import 'dart:async';

import 'package:get_it/get_it.dart' hide Disposable;

import '../util/disposable.dart';
import 'registry.dart';

/// [Registry] backed by a private get_it container.
final class GetItRegistry implements Registry {
  GetItRegistry({GetIt? getIt}) : _getIt = getIt ?? GetIt.asNewInstance();

  final GetIt _getIt;
  final List<FutureOr<void> Function()> _owned = <FutureOr<void> Function()>[];
  Future<void>? _disposeFuture;

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
    _ensureOpen();
    _getIt.registerSingleton<T>(instance, instanceName: instanceName);
  }

  @override
  void registerOwned<T extends Object>(
    T instance, {
    String? instanceName,
    FutureOr<void> Function()? dispose,
  }) {
    _ensureOpen();
    registerSingleton<T>(instance, instanceName: instanceName);
    final callback = dispose ?? _inferredDispose(instance);
    if (callback != null) {
      _owned.add(callback);
    }
  }

  @override
  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    _ensureOpen();
    _getIt.registerLazySingleton<T>(factory, instanceName: instanceName);
  }

  @override
  void registerFactory<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    _ensureOpen();
    _getIt.registerFactory<T>(factory, instanceName: instanceName);
  }

  @override
  void unregister<T extends Object>({String? instanceName}) {
    _getIt.unregister<T>(instanceName: instanceName);
  }

  @override
  Future<void> dispose() => _disposeFuture ??= Future<void>.microtask(_dispose);

  Future<void> _dispose() async {
    Object? firstError;
    StackTrace? firstStackTrace;
    for (final callback in _owned.reversed) {
      try {
        await callback();
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    _owned.clear();
    // Owned callbacks already ran; clearing without dispose avoids a second
    // pass over the same registrations.
    await _getIt.reset(dispose: false);
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  FutureOr<void> Function()? _inferredDispose(Object instance) {
    if (instance is Disposable) {
      return instance.dispose;
    }
    return null;
  }

  void _ensureOpen() {
    if (_disposeFuture != null) {
      throw StateError('The registry has been disposed.');
    }
  }
}
