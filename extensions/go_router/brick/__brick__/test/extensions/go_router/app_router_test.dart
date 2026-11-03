import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/app/app_route.dart';
import 'package:{{app_name}}/extensions/go_router/app_router.dart';
import 'package:{{app_name}}/extensions/go_router/app_routes.dart';
import 'package:{{app_name}}/extensions/go_router/router_config.dart';
import 'package:{{app_name}}/extensions/go_router/sign_in_page_builder.dart';

import 'test_support.dart';

void main() {
  testWidgets('builds the router from application routes', (tester) async {
    final registry = _registry(signedIn: true);
    _addRoute(registry, AppRoutes.home, 'home', const Text('Beranda'));

    final appRouter = AppRouter(registry: registry);

    expect(appRouter.router, isA<GoRouter>());
    await pumpRouter(tester, appRouter.router);

    expect(find.text('Beranda'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('includes routes contributed through router.routes', (
    tester,
  ) async {
    final registry = _registry(signedIn: true);
    _addRoute(registry, '/orders/:id', 'order', const Text('Detail pesanan'));

    final appRouter = AppRouter(registry: registry);

    expect(
      appRouter.router.configuration.routes.whereType<GoRoute>().map(
        (GoRoute route) => route.path,
      ),
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
    final registry = _registry(signedIn: true);
    _addRoute(registry, '/explore', 'explore', const Text('Jelajah'));
    final appRouter = AppRouter(
      registry: registry,
      config: const AppRouterConfig(initialLocation: '/explore'),
    );

    await pumpRouter(tester, appRouter.router);

    expect(find.text('Jelajah'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('applies the auth guard and refreshes with the session', (
    tester,
  ) async {
    final session = SessionController(
      initialStatus: SessionStatus.unauthenticated,
    );
    final registry = _registry(session: session);
    _addRoute(registry, AppRoutes.home, AppRoutes.homeName, const Text('Home'));
    registry.registerSingleton<SignInPageBuilder>(const _CustomSignInBuilder());

    final appRouter = AppRouter(
      registry: registry,
      config: const AppRouterConfig(enableAuthRedirect: true),
    );

    await pumpRouter(tester, appRouter.router);
    expect(find.byKey(const Key('custom-sign-in')), findsOneWidget);

    session.setSession(const AuthSession(userId: 'user-1'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    session.markUnauthenticated();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('custom-sign-in')), findsOneWidget);

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
    final registry = _registry(
      signedIn: true,
      deepLinks: deepLinks,
      notifications: notifications,
    );
    _addRoute(registry, '/explore', 'explore', const Text('Jelajah'));
    _addRoute(registry, AppRoutes.home, AppRoutes.homeName, const Text('Home'));
    final appRouter = AppRouter(registry: registry);

    appRouter.start();
    await pumpRouter(tester, appRouter.router);
    expect(
      appRouter.router.routerDelegate.currentConfiguration.uri.path,
      '/explore',
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
      '/explore',
    );

    expect(deepLinks.disposed, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('throws when auth redirect has no sign-in page', (tester) async {
    final registry = _registry(signedIn: false);

    expect(
      () => AppRouter(
        registry: registry,
        config: const AppRouterConfig(enableAuthRedirect: true),
      ),
      throwsStateError,
    );
  });

  testWidgets('omits the sign-in route without a builder', (tester) async {
    final registry = _registry(signedIn: true);
    _addRoute(registry, AppRoutes.home, AppRoutes.homeName, const Text('Home'));

    final appRouter = AppRouter(registry: registry);

    expect(
      appRouter.router.configuration.routes.whereType<GoRoute>().map(
        (GoRoute route) => route.path,
      ),
      isNot(contains(AppRoutes.signIn)),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });

  testWidgets('uses the application supplied error page', (tester) async {
    final registry = _registry(signedIn: true);
    final appRouter = AppRouter(
      registry: registry,
      config: AppRouterConfig(
        initialLocation: '/tidak-ada',
        errorBuilder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('Tidak ditemukan', key: Key('app-error'))),
      ),
    );

    await pumpRouter(tester, appRouter.router);

    expect(find.byKey(const Key('app-error')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await appRouter.dispose();
  });
}

Registry _registry({
  SessionController? session,
  bool signedIn = false,
  FakeDeepLinks? deepLinks,
  FakeNotifications? notifications,
}) {
  return createTestRegistry(
    sessionController:
        session ??
        SessionController(
          initialStatus: signedIn
              ? SessionStatus.authenticated
              : SessionStatus.unauthenticated,
        ),
    deepLinks: deepLinks,
    notifications: notifications,
  );
}

void _addRoute(Registry registry, String path, String name, Widget child) {
  registry
      .read<SlotRegistry>()
      .open<AppRoute>(SlotNames.routerRoutes)
      .add(
        AppRoute(
          path: path,
          name: name,
          builder: (BuildContext context) => Scaffold(body: child),
        ),
      );
}

final class _CustomSignInBuilder implements SignInPageBuilder {
  const _CustomSignInBuilder();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Masuk aplikasi', key: Key('custom-sign-in')));
}
