import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/go_router/auth_redirect.dart';
import 'package:{{app_name}}/extensions/go_router/route_guard.dart';

void main() {
  const guard = AuthRedirect();

  test('sends signed-out visitors to sign-in', () {
    expect(
      guard.redirect(
        const RouteGuardContext(location: '/', isAuthenticated: false),
      ),
      '/sign-in',
    );
    expect(
      guard.redirect(
        const RouteGuardContext(location: '/explore', isAuthenticated: false),
      ),
      '/sign-in?returnTo=%2Fexplore',
    );
  });

  test('keeps signed-out visitors on sign-in', () {
    expect(
      guard.redirect(
        const RouteGuardContext(
          location: '/sign-in',
          isAuthenticated: false,
        ),
      ),
      isNull,
    );
  });

  test('unknown sessions wait without losing the requested query', () {
    final target = guard.redirect(const RouteGuardContext(
      location: '/orders/42?tab=items', sessionStatus: SessionStatus.unknown,
    ));
    final uri = Uri.parse(target!);
    expect(uri.path, '/session-loading');
    expect(uri.queryParameters['returnTo'], '/orders/42?tab=items');
    final signedOut = guard.redirect(RouteGuardContext(
      location: target, sessionStatus: SessionStatus.unauthenticated,
    ));
    expect(Uri.parse(signedOut!).path, '/sign-in');
    expect(guard.redirect(RouteGuardContext(
      location: signedOut, sessionStatus: SessionStatus.authenticated,
    )), '/orders/42?tab=items');
    expect(guard.redirect(RouteGuardContext(
      location: target, sessionStatus: SessionStatus.authenticated,
    )), '/orders/42?tab=items');
  });

  test('untrusted return destinations cannot leave the app or create loops', () {
    for (final target in ['https://evil.test', '//evil.test', '/%2f%2fevil.test',
      '/\\evil.test', '/sign-in', '/session-loading']) {
      final uri = Uri(path: '/sign-in', queryParameters: {'returnTo': target});
      expect(guard.redirect(RouteGuardContext(
        location: uri.toString(), isAuthenticated: true,
      )), '/', reason: target);
    }
  });

  test('sends signed-in visitors away from sign-in', () {
    expect(
      guard.redirect(
        const RouteGuardContext(location: '/sign-in', isAuthenticated: true),
      ),
      '/',
    );
  });

  test('leaves signed-in visitors on other routes', () {
    expect(
      guard.redirect(
        const RouteGuardContext(location: '/explore', isAuthenticated: true),
      ),
      isNull,
    );
  });

  test('recognises nested sign-in paths', () {
    expect(
      guard.redirect(
        const RouteGuardContext(
          location: '/sign-in/reset',
          isAuthenticated: false,
        ),
      ),
      isNull,
    );
  });
}
