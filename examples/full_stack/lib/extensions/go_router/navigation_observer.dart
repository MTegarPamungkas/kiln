import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';

/// Logs navigation and reports the active screen to analytics.
///
/// Both integrations are optional: when `AppLogger` or `Analytics` is not
/// registered the observer silently skips that side effect.
final class NavigationObserver extends NavigatorObserver {
  NavigationObserver({
    required this.registry,
    this.screenEvent = 'screen_view',
  });

  final Registry registry;

  /// Event name sent to [Analytics].
  final String screenEvent;

  String? _lastScreen;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _record(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _record(newRoute);
  }

  void _record(Route<dynamic>? route) {
    final screen = route?.settings.name;
    if (screen == null || screen.isEmpty || screen == _lastScreen) {
      return;
    }
    _lastScreen = screen;

    registry.readOrNull<AppLogger>()?.debug(
      'Navigation to $screen',
      data: <String, Object?>{'screen': screen},
    );

    final analytics = registry.readOrNull<Analytics>();
    if (analytics != null) {
      unawaited(
        analytics.capture(
          screenEvent,
          properties: <String, Object?>{'screen': screen},
        ),
      );
    }
  }
}
