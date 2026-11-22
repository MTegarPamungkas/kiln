/// Paths and names of the routes owned by the navigation extension.
///
/// Feature routes contributed through the `router.routes` slot keep their own
/// constants next to the feature that owns them.
abstract final class AppRoutes {
  /// Default application landing location.
  static const String home = '/';

  /// Sign-in location used by the auth redirect.
  static const String signIn = '/sign-in';

  /// Waiting location while an authentication provider restores its session.
  static const String sessionLoading = '/session-loading';

  static const String homeName = 'home';
  static const String signInName = 'signIn';
  static const String sessionLoadingName = 'sessionLoading';

  /// Every path owned by this extension.
  static const List<String> paths = <String>[home, signIn, sessionLoading];

  /// Every route name owned by this extension.
  static const List<String> names = <String>[homeName, signInName, sessionLoadingName];
}
