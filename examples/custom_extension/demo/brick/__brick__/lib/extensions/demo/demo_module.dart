import 'package:kiln_core/kiln_core.dart';

import 'demo_config.dart';

/// Registers the Demo extension services in the Registry.
final class DemoModule extends KilnModule {
  const DemoModule();

  @override
  String get id => 'demo';

  @override
  Set<String> get provides => const {'demo'};

  @override
  void register(Registry registry) {
    registry.registerSingleton<DemoConfig>(
      DemoConfig.defaults,
    );
  }
}
