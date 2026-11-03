import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/go_router/navigation_observer.dart';

import 'test_support.dart';

void main() {
  testWidgets('logs navigation and captures screens when contracts exist', (
    tester,
  ) async {
    final logger = RecordingLogger();
    final analytics = FakeAnalytics();
    final registry = createTestRegistry(
      logger: logger,
      analytics: analytics,
      sessionController: SessionController(
        initialStatus: SessionStatus.authenticated,
      ),
    );
    final observer = NavigationObserver(registry: registry);
    final router = GoRouter(
      initialLocation: '/',
      observers: <NavigatorObserver>[observer],
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: 'home',
          builder: (BuildContext context, GoRouterState state) =>
              const Text('Beranda'),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (BuildContext context, GoRouterState state) =>
              const Text('Profil'),
        ),
      ],
    );

    await pumpRouter(tester, router);

    expect(logger.messages, contains('Navigation to home'));
    expect(analytics.events, isNotEmpty);
    expect(analytics.events.last.name, 'screen_view');
    expect(analytics.events.last.properties['screen'], 'home');

    router.go('/profile');
    await tester.pumpAndSettle();

    expect(logger.messages, contains('Navigation to profile'));
    expect(analytics.events.last.properties['screen'], 'profile');
  });

  testWidgets('does nothing when contracts are absent', (tester) async {
    final registry = GetItRegistry();
    final observer = NavigationObserver(registry: registry);
    final router = GoRouter(
      initialLocation: '/',
      observers: <NavigatorObserver>[observer],
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: 'home',
          builder: (BuildContext context, GoRouterState state) =>
              const Text('Beranda'),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (BuildContext context, GoRouterState state) =>
              const Text('Profil'),
        ),
      ],
    );

    await pumpRouter(tester, router);
    router.go('/profile');
    await tester.pumpAndSettle();

    expect(find.text('Profil'), findsOneWidget);
  });
}
