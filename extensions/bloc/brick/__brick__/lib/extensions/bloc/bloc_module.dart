import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/app/app_wrappers.dart';
import 'package:{{app_name}}/app/bloc_providers.dart';
import 'package:{{app_name}}/core/bloc/app_bloc_observer.dart';

import 'bloc_support.dart';

/// Registers the Bloc state management layer.
final class BlocModule extends KilnModule {
  const BlocModule();

  @override
  String get id => 'bloc';

  @override
  Set<String> get provides => const <String>{'state_bloc'};

  @override
  Set<String> get optionalRequires => const <String>{'logger'};

  @override
  void register(Registry registry) {
    final logger = registry.readOrNull<AppLogger>();
    if (logger != null) {
      Bloc.observer = AppBlocObserver(logger: logger);
    }
    var slots = registry.readOrNull<SlotRegistry>();
    if (slots == null) {
      slots = SlotRegistry();
      registry.registerSingleton<SlotRegistry>(slots);
    }
    slots
        .open<AppWrapper>(SlotNames.appWrappers)
        .add(buildBlocAppWrapper(registry), priority: 0, owner: 'bloc');
    registry.registerSingleton<BlocSupport>(
      BlocSupport(observerAttached: logger != null),
    );
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<BlocSupport>().info;
  }
}
