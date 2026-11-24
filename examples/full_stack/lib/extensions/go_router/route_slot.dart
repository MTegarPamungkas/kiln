import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:full_stack/app/app_route.dart';

/// Converts transport-neutral slot contributions into go_router routes.
abstract final class RouteSlot {
  /// Converts one [AppRoute] into a [GoRoute].
  ///
  /// A missing route name leaves named navigation disabled for that route;
  /// the path still works and go_router falls back to the path as the page
  /// name for observers.
  static GoRoute toGoRoute(AppRoute route) {
    return GoRoute(
      path: route.path,
      name: route.name,
      builder: (BuildContext context, GoRouterState state) =>
          route.builder(context),
    );
  }

  /// Converts an ordered slot contribution list into [GoRoute]s.
  static List<GoRoute> toGoRoutes(Iterable<AppRoute> routes) {
    return <GoRoute>[
      for (final route in routes) toGoRoute(route),
    ];
  }
}
