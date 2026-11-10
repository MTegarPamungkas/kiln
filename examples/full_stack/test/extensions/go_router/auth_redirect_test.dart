import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/go_router/auth_redirect.dart';
import 'package:full_stack/extensions/go_router/route_guard.dart';

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
      '/sign-in',
    );
  });

  test('keeps signed-out visitors on sign-in', () {
    expect(
      guard.redirect(
        const RouteGuardContext(location: '/sign-in', isAuthenticated: false),
      ),
      isNull,
    );
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
