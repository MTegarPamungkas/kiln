import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/riverpod/kiln_providers.dart';

/// Creates a provider container with the Registry overridden for tests.
ProviderContainer testProviderContainer(Registry registry) {
  return ProviderContainer(
    overrides: [registryProvider.overrideWithValue(registry)],
  );
}
