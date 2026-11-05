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
  });

  /// Location shown when the platform does not provide one.
  final String initialLocation;

  /// Prints go_router diagnostics for every navigation decision.
  ///
  /// Keep this `false` in release builds; enable it through a flavor config
  /// instead of hard coding it.
  final bool debugLogDiagnostics;

  /// Replaces the default not found page when the application needs its own
  /// error screen.
  final GoRouterWidgetBuilder? errorBuilder;

  /// Extra navigator observers, for example a custom analytics tracker.
  final List<NavigatorObserver> observers;
}
