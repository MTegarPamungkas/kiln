import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';

/// The Registry injected by the application wrapper.
final registryProvider = Provider<Registry>(
  (ref) => throw StateError('registryProvider must be overridden'),
);

/// Reads a contract from the injected Registry.
Provider<T> kilnProvider<T extends Object>() {
  return Provider<T>((ref) => ref.watch(registryProvider).read<T>());
}
