import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:{{app_name}}/extensions/go_router/app_routes.dart';
import 'package:{{app_name}}/extensions/go_router/shell_scaffold.dart';

import 'test_support.dart';

void main() {
  testWidgets('shows the navigation bar and switches tabs', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: <RouteBase>[buildShellRoute()],
    );

    await pumpRouter(tester, router);

    expect(find.byKey(ShellScaffold.navigationBarKey), findsOneWidget);
    expect(find.byKey(const Key('home-tab')), findsOneWidget);
    expect(find.byKey(const Key('explore-tab')), findsNothing);

    await tester.tap(find.text('Jelajahi'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('explore-tab')), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.explore,
    );

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-tab')), findsOneWidget);
  });
}
