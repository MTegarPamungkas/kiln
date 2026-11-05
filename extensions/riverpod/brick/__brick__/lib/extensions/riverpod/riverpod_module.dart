import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/app/app_wrappers.dart';
import 'package:{{app_name}}/app/provider_root.dart';

import 'riverpod_support.dart';

/// Registers the Riverpod state management layer.
final class RiverpodModule extends KilnModule {
  const RiverpodModule();

  @override
  String get id => 'riverpod';

  @override
  Set<String> get provides => const <String>{'state_riverpod'};

  @override
  void register(Registry registry) {
    var slots = registry.readOrNull<SlotRegistry>();
    if (slots == null) {
      slots = SlotRegistry();
      registry.registerSingleton<SlotRegistry>(slots);
    }
    slots
        .open<AppWrapper>(SlotNames.appWrappers)
        .add(buildRiverpodAppWrapper(registry), priority: 0, owner: 'riverpod');
    registry.registerSingleton<RiverpodSupport>(const RiverpodSupport());
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<RiverpodSupport>().info;
  }
}
