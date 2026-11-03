import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Typed settings used while building the application [GoRouter].
final class AppRouterConfig {
  const AppRouterConfig({
    this.initialLocation = AppRoutes.home,
    this.debugLogDiagnostics = false,
    this.errorBuilder,
    this.observers = const <NavigatorObserver>[],
    this.enableAuthRedirect = false,
  });

  /// Location shown when the platform does not provide one.
  final String initialLocation;

  /// Whether signed-out visitors are redirected to `/sign-in`.
  ///
  /// Auth policy belongs to the application. Enable this when the app wants a
  /// login wall; public pages can then keep `false` and guard specific routes
  /// with their own `RouteGuard`.
  final bool enableAuthRedirect;

  /// Prints go_router diagnostics for every navigation decision.
  ///
  /// Keep this `false` in release builds; enable it through a flavor config
  /// instead of hard coding it.
  final bool debugLogDiagnostics;

  /// Renders unmatched locations. The application supplies this builder; the
  /// extension does not ship an error screen.
  final GoRouterWidgetBuilder? errorBuilder;

  /// Extra navigator observers, for example a custom analytics tracker.
  final List<NavigatorObserver> observers;
}
