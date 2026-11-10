import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/app/app_route.dart';
import 'package:full_stack/extensions/go_router/app_router.dart';
import 'package:full_stack/extensions/go_router/app_routes.dart';
import 'package:full_stack/extensions/go_router/go_router_module.dart';
import 'package:full_stack/extensions/go_router/go_router_support.dart';
import 'package:full_stack/extensions/go_router/router_config.dart';

import 'test_support.dart';

void main() {
  test('registers the router, config, and the route slot', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final registry = GetItRegistry();
    final module = GoRouterModule();

    module.register(registry);

    final router = registry.read<RouterConfig<Object>>();
    expect(router, isA<GoRouter>());
    expect(registry.read<AppRouter>().router, same(router));
    expect(registry.read<AppRouterConfig>(), isA<AppRouterConfig>());
    expect(registry.read<GoRouterSupport>(), isA<GoRouterSupport>());
    expect(
      registry.read<SlotRegistry>().find<AppRoute>(SlotNames.routerRoutes),
      isNotNull,
    );
  });

  test('keeps existing slot contributions and converts them', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final registry = GetItRegistry();
    final slots = SlotRegistry();
    registry.registerSingleton<SlotRegistry>(slots);
    slots
        .open<AppRoute>(SlotNames.routerRoutes)
        .add(
          AppRoute(
            path: '/settings',
            name: 'settings',
            builder: (BuildContext context) => const SizedBox.shrink(),
          ),
        );

    GoRouterModule().register(registry);

    final routes = registry
        .read<AppRouter>()
        .router
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((GoRoute route) => route.path);
    expect(routes, contains('/settings'));
  });

  test('honours an application supplied config', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final registry = GetItRegistry();
    const config = AppRouterConfig(debugLogDiagnostics: true);
    registry.registerSingleton<AppRouterConfig>(config);

    GoRouterModule().register(registry);

    expect(registry.read<AppRouterConfig>(), same(config));
    expect(registry.read<AppRouter>().config, same(config));
  });

  testWidgets('connects deep links during ready', (tester) async {
    final deepLinks = FakeDeepLinks();
    final registry = createTestRegistry(
      deepLinks: deepLinks,
      sessionController: SessionController(
        initialStatus: SessionStatus.authenticated,
      ),
    );
    registry
        .read<SlotRegistry>()
        .open<AppRoute>(SlotNames.routerRoutes)
        .add(
          AppRoute(
            path: AppRoutes.home,
            name: AppRoutes.homeName,
            builder: (BuildContext context) => const SizedBox.shrink(),
          ),
        );
    final module = GoRouterModule();
    module.register(registry);
    module.ready(registry);

    final router = registry.read<RouterConfig<Object>>() as GoRouter;
    await pumpRouter(tester, router);
    deepLinks.emit(Uri.parse('https://example.com/'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);

    await tester.pumpWidget(const SizedBox.shrink());
    await module.dispose();
  });
}
