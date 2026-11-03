import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/app/app_route.dart';

import 'app_router.dart';
import 'router_config.dart';

/// Registers navigation and opens the `router.routes` slot.
final class GoRouterModule extends KilnModule {
  GoRouterModule();

  AppRouter? _appRouter;

  @override
  String get id => 'go_router';

  @override
  Set<String> get provides => const <String>{'navigation'};

  @override
  Set<String> get optionalRequires => const <String>{
    'deep_links',
    'notifications',
    'analytics',
    'logger',
  };

  @override
  void register(Registry registry) {
    var slots = registry.readOrNull<SlotRegistry>();
    if (slots == null) {
      slots = SlotRegistry();
      registry.registerSingleton<SlotRegistry>(slots);
    }
    slots.open<AppRoute>(SlotNames.routerRoutes);

    const config = AppRouterConfig();
    final appRouter = AppRouter(registry: registry, config: config);
    _appRouter = appRouter;

    registry
      ..registerSingleton<AppRouterConfig>(config)
      ..registerSingleton<AppRouter>(appRouter)
      ..registerSingleton<RouterConfig<Object>>(appRouter.router);
  }

  @override
  void ready(Registry registry) {
    registry.readOrNull<AppRouter>()?.start();
  }

  @override
  Future<void> dispose() async {
    final appRouter = _appRouter;
    _appRouter = null;
    await appRouter?.dispose();
  }
}
