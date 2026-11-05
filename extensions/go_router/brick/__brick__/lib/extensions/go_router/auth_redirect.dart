import 'app_routes.dart';
import 'route_guard.dart';

/// Redirects visitors based on the session exposed by the registry.
///
/// Signed-out visitors may only reach [signInPath]; signed-in visitors are sent
/// away from it to [signedInPath]. Other guards can be placed before this one
/// to add feature gates.
final class AuthRedirect implements RouteGuard {
  const AuthRedirect({
    this.signInPath = AppRoutes.signIn,
    this.signedInPath = AppRoutes.home,
  });

  final String signInPath;
  final String signedInPath;

  @override
  String? redirect(RouteGuardContext context) {
    final atSignIn = _isAtSignIn(context.location);
    if (!context.isAuthenticated) {
      return atSignIn ? null : signInPath;
    }
    return atSignIn ? signedInPath : null;
  }

  bool _isAtSignIn(String location) {
    return location == signInPath || location.startsWith('$signInPath/');
  }
}
