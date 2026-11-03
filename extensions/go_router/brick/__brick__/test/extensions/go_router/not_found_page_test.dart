import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:{{app_name}}/extensions/go_router/not_found_page.dart';

import 'test_support.dart';

void main() {
  testWidgets('renders friendly Indonesian copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotFoundPage()));

    expect(find.text('Halaman tidak ditemukan'), findsOneWidget);
    expect(find.text('Kembali ke beranda'), findsOneWidget);
  });

  testWidgets('is shown by the router for an unknown location', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/tidak-ada',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const Text('Beranda'),
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) =>
          const NotFoundPage(),
    );

    await pumpRouter(tester, router);

    expect(find.byKey(NotFoundPage.pageKey), findsOneWidget);
    expect(find.text('Halaman tidak ditemukan'), findsOneWidget);
  });

  testWidgets('navigates home when the button is pressed', (tester) async {
    var homeRequests = 0;
    await tester.pumpWidget(
      MaterialApp(home: NotFoundPage(onHome: () => homeRequests++)),
    );

    await tester.tap(find.text('Kembali ke beranda'));

    expect(homeRequests, 1);
  });
}
