import 'package:kiln_core/kiln_core.dart';

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
    this.loadingPath = AppRoutes.sessionLoading,
  });

  final String signInPath;
  final String signedInPath;
  final String loadingPath;

  @override
  String? redirect(RouteGuardContext context) {
    final uri = context.uri;
    final atSignIn = _isAtSignIn(uri.path);
    final atLoading = uri.path == loadingPath;
    final destination = atSignIn || atLoading
        ? _safeDestination(uri.queryParameters['returnTo'])
        : _safeDestination(uri.toString());
    switch (context.effectiveSessionStatus) {
      case SessionStatus.unknown:
        return atLoading ? null : _withDestination(loadingPath, destination);
      case SessionStatus.unauthenticated:
        return atSignIn ? null : _withDestination(signInPath, destination);
      case SessionStatus.authenticated:
        return atSignIn || atLoading ? destination ?? signedInPath : null;
    }
  }

  String _withDestination(String path, String? destination) =>
      destination == null || destination == signedInPath
          ? path
          : Uri(path: path, queryParameters: {'returnTo': destination}).toString();

  String? _safeDestination(String? value) {
    if (value == null || !value.startsWith('/') || value.contains('\\')) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.hasScheme || uri.hasAuthority) {
      return null;
    }
    final String decodedPath;
    try {
      decodedPath = Uri.decodeComponent(uri.path);
    } on FormatException {
      return null;
    }
    final normalized = Uri(path: decodedPath).normalizePath().path;
    if (decodedPath.startsWith('//') || decodedPath.contains('\\') ||
        RegExp(r'%2f|%5c', caseSensitive: false).hasMatch(decodedPath) ||
        decodedPath.codeUnits.any((unit) => unit < 32) ||
        _isAtSignIn(normalized) || normalized == loadingPath) {
      return null;
    }
    return uri.toString();
  }

  bool _isAtSignIn(String location) {
    return location == signInPath || location.startsWith('$signInPath/');
  }
}
