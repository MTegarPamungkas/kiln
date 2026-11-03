import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:full_stack/app/app_route.dart';
import 'package:full_stack/extensions/go_router/route_slot.dart';

import 'test_support.dart';

void main() {
  test('converts an AppRoute into a GoRoute', () {
    final goRoute = RouteSlot.toGoRoute(
      AppRoute(
        path: '/orders/:id',
        name: 'order',
        builder: (BuildContext context) => const Text('Pesanan'),
      ),
    );

    expect(goRoute.path, '/orders/:id');
    expect(goRoute.name, 'order');
    expect(goRoute.builder, isNotNull);
  });

  test('keeps slot order', () {
    final routes = RouteSlot.toGoRoutes(<AppRoute>[
      AppRoute(
        path: '/first',
        builder: (BuildContext context) => const SizedBox.shrink(),
      ),
      AppRoute(
        path: '/second',
        builder: (BuildContext context) => const SizedBox.shrink(),
      ),
    ]);

    expect(routes.map((GoRoute route) => route.path), <String>[
      '/first',
      '/second',
    ]);
  });

  testWidgets('the converted route builds its widget', (tester) async {
    final goRoute = RouteSlot.toGoRoute(
      AppRoute(
        path: '/orders/:id',
        name: 'order',
        builder: (BuildContext context) => const Text('Detail pesanan'),
      ),
    );
    final router = GoRouter(
      initialLocation: '/orders/42',
      routes: <RouteBase>[goRoute],
    );

    await pumpRouter(tester, router);

    expect(find.text('Detail pesanan'), findsOneWidget);
  });
}
