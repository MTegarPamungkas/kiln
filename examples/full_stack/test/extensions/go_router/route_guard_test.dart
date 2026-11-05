import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/go_router/route_guard.dart';

import 'test_support.dart';

void main() {
  test('runs guards in order and stops at the first redirect', () {
    final calls = <String>[];
    final guards = <RouteGuard>[
      FakeRouteGuard(
        onRedirect: (RouteGuardContext context) {
          calls.add('first');
          return null;
        },
      ),
      FakeRouteGuard(
        onRedirect: (RouteGuardContext context) {
          calls.add('second');
          return '/sign-in';
        },
      ),
      FakeRouteGuard(
        onRedirect: (RouteGuardContext context) {
          calls.add('third');
          return '/other';
        },
      ),
    ];

    final target = evaluateRouteGuards(
      guards,
      const RouteGuardContext(location: '/'),
    );

    expect(target, '/sign-in');
    expect(calls, <String>['first', 'second']);
  });

  test('treats an identity redirect as no redirect', () {
    final calls = <String>[];
    final guards = <RouteGuard>[
      FakeRouteGuard(
        onRedirect: (RouteGuardContext context) {
          calls.add('identity');
          return context.location;
        },
      ),
      FakeRouteGuard(
        onRedirect: (RouteGuardContext context) {
          calls.add('next');
          return '/next';
        },
      ),
    ];

    final target = evaluateRouteGuards(
      guards,
      const RouteGuardContext(location: '/'),
    );

    expect(target, '/next');
    expect(calls, <String>['identity', 'next']);
  });

  test('returns null when no guard redirects', () {
    expect(
      evaluateRouteGuards(
        const <RouteGuard>[],
        const RouteGuardContext(location: '/'),
      ),
      isNull,
    );
  });
}
