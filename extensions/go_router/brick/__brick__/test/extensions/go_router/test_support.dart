import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:{{app_name}}/extensions/go_router/route_guard.dart';

/// Pumps a router backed application and settles its first frame.
Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

/// [RouteGuard] whose decision is supplied by the test.
final class FakeRouteGuard implements RouteGuard {
  FakeRouteGuard({required this.onRedirect});

  final String? Function(RouteGuardContext context) onRedirect;

  @override
  String? redirect(RouteGuardContext context) => onRedirect(context);
}
