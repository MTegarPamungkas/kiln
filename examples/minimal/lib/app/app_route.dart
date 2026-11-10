import 'package:flutter/widgets.dart';

/// Transport-neutral route contributed through the `router.routes` slot.
///
/// Extensions such as `go_router` translate [AppRoute] into their own route
/// type, so contributors never import a navigation package.
class AppRoute {
  const AppRoute({required this.path, required this.builder, this.name});

  final String path;
  final String? name;
  final WidgetBuilder builder;
}
