import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/app/app_route.dart';
import 'package:full_stack/extensions/go_router/app_router.dart';
import 'package:full_stack/extensions/go_router/app_routes.dart';
import 'package:full_stack/extensions/go_router/router_config.dart';

import 'test_support.dart';

void main() {
  testWidgets('builds the shell from the initial location', (tester) async {
    final registry = createTestRegistry(
      sessionController: SessionController(
        initialStatus: SessionStatus.authenticated,
      ),
    );
    final appRouter = AppRouter(registry: registry);

    expect(appRouter.router, isA<GoRouter>());
    await pumpRouter(tester, appRouter.router);

    expect(find.byKey(const Key('home-tab')), findsOneWidget);
    final routes = appRouter.router.configuration.routes;
    expect(routes.whereType<ShellRoute>(), isNotEmpty);
    expect(
      routes.whereType<GoRoute>().map((GoRoute route) => route.path),
      contains(AppRoutes.signIn),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('includes routes contributed through router.routes', (
    tester,
  ) async {
    final registry = createTestRegistry(
      sessionController: SessionController(
        initialStatus: SessionStatus.authenticated,
      ),
    );
    registry.read<SlotRegistry>().open<AppRoute>(SlotNames.routerRoutes).add(
      AppRoute(
        path: '/orders/:id',
        name: 'order',
        builder: (BuildContext context) =>
            const Scaffold(body: Text('Detail pesanan')),
      ),
    );
    final appRouter = AppRouter(registry: registry);

    expect(
      appRouter.router.configuration.routes
          .whereType<GoRoute>()
          .map((GoRoute route) => route.path),
      contains('/orders/:id'),
    );

    await pumpRouter(tester, appRouter.router);
    appRouter.router.go('/orders/42');
    await tester.pumpAndSettle();

    expect(find.text('Detail pesanan'), findsOneWidget);
    expect(
      appRouter.router.routerDelegate.currentConfiguration.uri.path,
      '/orders/42',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('honours the configured initial location', (tester) async {
    final registry = createTestRegistry(
      sessionController: SessionController(
        initialStatus: SessionStatus.authenticated,
      ),
    );
    const config = AppRouterConfig(initialLocation: AppRoutes.explore);
    final appRouter = AppRouter(registry: registry, config: config);

    await pumpRouter(tester, appRouter.router);

    expect(find.byKey(const Key('explore-tab')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('applies the auth guard and refreshes with the session', (
    tester,
  ) async {
    final session = SessionController(
      initialStatus: SessionStatus.unauthenticated,
    );
    final registry = createTestRegistry(sessionController: session);
    final appRouter = AppRouter(registry: registry);

    await pumpRouter(tester, appRouter.router);
    expect(find.byKey(const Key('sign-in-page')), findsOneWidget);

    session.setSession(const AuthSession(userId: 'user-1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-tab')), findsOneWidget);

    session.markUnauthenticated();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign-in-page')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('follows deep links and notification taps when started', (
    tester,
  ) async {
    final deepLinks = FakeDeepLinks(
      initialLink: Uri.parse('https://example.com/explore'),
    );
    final notifications = FakeNotifications();
    final registry = createTestRegistry(
      deepLinks: deepLinks,
      notifications: notifications,
      sessionController: SessionController(
        initialStatus: SessionStatus.authenticated,
      ),
    );
    final appRouter = AppRouter(registry: registry);

    appRouter.start();
    await pumpRouter(tester, appRouter.router);
    expect(
      appRouter.router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.explore,
    );

    notifications.emitTap('{"route":"/"}');
    await tester.pumpAndSettle();
    expect(
      appRouter.router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.home,
    );

    deepLinks.emit(Uri.parse('myapp://explore'));
    await tester.pumpAndSettle();
    expect(
      appRouter.router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.explore,
    );

    deepLinks.emit(Uri.parse('mailto:halo@example.com'));
    await tester.pumpAndSettle();
    expect(
      appRouter.router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.explore,
    );

    expect(deepLinks.disposed, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('shows the not found page for an unknown location', (
    tester,
  ) async {
    final registry = GetItRegistry();
    final appRouter = AppRouter(
      registry: registry,
      config: const AppRouterConfig(initialLocation: '/tidak-ada'),
    );

    await pumpRouter(tester, appRouter.router);

    expect(find.byKey(const Key('not-found-page')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });
}
