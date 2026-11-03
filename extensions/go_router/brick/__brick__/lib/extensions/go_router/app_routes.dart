/// Paths and names of the routes owned by the navigation extension.
///
/// Feature routes contributed through the `router.routes` slot keep their own
/// constants next to the feature that owns them.
abstract final class AppRoutes {
  /// Landing tab inside the shell.
  static const String home = '/';

  /// Second sample tab inside the shell.
  static const String explore = '/explore';

  /// Sign-in screen rendered outside the shell.
  static const String signIn = '/sign-in';

  static const String homeName = 'home';
  static const String exploreName = 'explore';
  static const String signInName = 'signIn';

  /// Every path owned by this extension.
  static const List<String> paths = <String>[home, explore, signIn];

  /// Every route name owned by this extension.
  static const List<String> names = <String>[
    homeName,
    exploreName,
    signInName,
  ];
}
