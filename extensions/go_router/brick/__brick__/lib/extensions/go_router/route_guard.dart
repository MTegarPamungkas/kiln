/// State passed to every [RouteGuard] during a redirect decision.
final class RouteGuardContext {
  const RouteGuardContext({
    required this.location,
    this.name,
    this.isAuthenticated = false,
  });

  /// Path being requested, without query parameters.
  final String location;

  /// Name of the matched route, when the route declares one.
  final String? name;

  /// Whether a session is currently authenticated.
  final bool isAuthenticated;
}

/// A synchronous redirect rule evaluated before a route is shown.
///
/// Return a location to redirect to, or `null` to let the next guard decide.
/// Guards must not navigate themselves; navigation is owned by the router.
abstract interface class RouteGuard {
  String? redirect(RouteGuardContext context);
}

/// Runs [guards] in order and returns the first redirect.
///
/// A guard that returns the current location is treated as "no redirect" so an
/// accidental identity rule cannot create a redirect loop.
String? evaluateRouteGuards(
  Iterable<RouteGuard> guards,
  RouteGuardContext context,
) {
  for (final guard in guards) {
    final target = guard.redirect(context);
    if (target == null || target.isEmpty || target == context.location) {
      continue;
    }
    return target;
  }
  return null;
}
