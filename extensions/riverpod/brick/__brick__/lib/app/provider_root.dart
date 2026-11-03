import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/app/app_wrappers.dart';
import 'package:{{app_name}}/core/riverpod/app_provider_observer.dart';
import 'package:{{app_name}}/core/riverpod/kiln_providers.dart';

/// Wraps the application with a ProviderScope backed by the Registry.
AppWrapper buildRiverpodAppWrapper(Registry registry) {
  final logger = registry.readOrNull<AppLogger>();

  return (context, child) => ProviderScope(
    overrides: [registryProvider.overrideWithValue(registry)],
    observers: [if (logger != null) AppProviderObserver(logger: logger)],
    child: child,
  );
}
