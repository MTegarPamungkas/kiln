import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/app/app_wrappers.dart';
import 'package:{{app_name}}/app/bloc_providers.dart';
import 'package:{{app_name}}/core/bloc/app_bloc_observer.dart';

/// Registers the Bloc state management layer.
final class BlocModule extends KilnModule {
  const BlocModule();

  @override
  String get id => 'bloc';

  @override
  Set<String> get provides => const <String>{'state_bloc'};

  @override
  void register(Registry registry) {
    final logger = registry.readOrNull<AppLogger>();
    if (logger != null) {
      Bloc.observer = AppBlocObserver(logger: logger);
    }
    registry
        .read<SlotRegistry>()
        .open<AppWrapper>(SlotNames.appWrappers)
        .add(buildBlocAppWrapper(registry), priority: 0, owner: 'bloc');
  }
}
