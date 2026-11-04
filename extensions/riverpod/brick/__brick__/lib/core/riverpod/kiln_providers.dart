import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';

/// The Registry injected by the application wrapper.
final registryProvider = Provider<Registry>(
  (ref) => throw StateError('registryProvider must be overridden'),
);

final Map<Type, Provider<Object?>> _kilnProviderCache =
    <Type, Provider<Object?>>{};

/// Reads a contract from the injected Registry.
///
/// Providers are cached by type, so `kilnProvider<Auth>()` always returns the
/// same [Provider] instance. Riverpod identifies providers by object identity,
/// so a stable instance lets every `ref.watch(kilnProvider<T>())` share a
/// single provider node instead of creating one per call.
Provider<T> kilnProvider<T extends Object>() {
  return _kilnProviderCache.putIfAbsent(
    T,
    () => Provider<T>(
      (ref) => ref.watch(registryProvider).read<T>(),
      name: 'kilnProvider<$T>',
    ),
  ) as Provider<T>;
}
