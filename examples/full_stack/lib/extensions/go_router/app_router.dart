import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/app/app_route.dart';

import 'app_routes.dart';
import 'auth_redirect.dart';
import 'deep_link_route_mapper.dart';
import 'navigation_observer.dart';
import 'notification_route_mapper.dart';
import 'not_found_page.dart';
import 'route_guard.dart';
import 'route_slot.dart';
import 'route_transitions.dart';
import 'router_config.dart';
import 'session_refresh_listenable.dart';
import 'shell_scaffold.dart';

/// Owns the application [GoRouter] and its optional integrations.
///
/// The router is built during module registration from the routes already
/// contributed to `router.routes`. Integrations with `DeepLinks`,
/// `Notifications`, `SessionController`, `AppLogger`, and `Analytics` are read
/// through the registry so the extension works in any combination.
final class AppRouter {
  AppRouter({
    required this.registry,
    this.config = const AppRouterConfig(),
    List<RouteGuard> guards = const <RouteGuard>[],
    this.deepLinkMapper = const DeepLinkRouteMapper(),
    this.notificationMapper = const NotificationRouteMapper(),
  }) {
    final session = registry.readOrNull<SessionController>();
    refreshListenable = session == null
        ? null
        : SessionRefreshListenable(session);
    navigationObserver = NavigationObserver(registry: registry);

    final slotRoutes =
        registry
            .readOrNull<SlotRegistry>()
            ?.find<AppRoute>(SlotNames.routerRoutes)
            ?.items ??
        const <AppRoute>[];

    final routeGuards = <RouteGuard>[
      if (session != null) const AuthRedirect(),
      ...guards,
    ];

    router = GoRouter(
      initialLocation: config.initialLocation,
      debugLogDiagnostics: config.debugLogDiagnostics,
      refreshListenable: refreshListenable,
      observers: <NavigatorObserver>[
        navigationObserver,
        ...config.observers,
      ],
      redirect: routeGuards.isEmpty
          ? null
          : (BuildContext context, GoRouterState state) {
              return evaluateRouteGuards(
                routeGuards,
                RouteGuardContext(
                  location: state.uri.path,
                  name: state.name,
                  isAuthenticated: session?.isAuthenticated ?? false,
                ),
              );
            },
      errorBuilder:
          config.errorBuilder ??
          (BuildContext context, GoRouterState state) => const NotFoundPage(),
      routes: <RouteBase>[
        buildShellRoute(),
        GoRoute(
          path: AppRoutes.signIn,
          name: AppRoutes.signInName,
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildRoutePage(
              state: state,
              platform: Theme.of(context).platform,
              child: const _SignInPage(),
            );
          },
        ),
        ...RouteSlot.toGoRoutes(slotRoutes),
      ],
    );
  }

  final Registry registry;
  final AppRouterConfig config;
  final DeepLinkRouteMapper deepLinkMapper;
  final NotificationRouteMapper notificationMapper;

  late final GoRouter router;
  late final NavigationObserver navigationObserver;
  late final SessionRefreshListenable? refreshListenable;

  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  bool _started = false;
  bool _disposed = false;

  /// Connects deep links and notification taps to the router.
  ///
  /// Call this from [KilnModule.ready] so providers registered after the router
  /// are still picked up. Calling it more than once is a no-op.
  void start() {
    if (_started || _disposed) {
      return;
    }
    _started = true;

    final deepLinks = registry.readOrNull<DeepLinks>();
    if (deepLinks != null) {
      _subscriptions.add(deepLinks.links.listen(_followUri));
      final initialLink = deepLinks.initialLink;
      if (initialLink != null) {
        _followUri(initialLink);
      }
    }

    final notifications = registry.readOrNull<Notifications>();
    if (notifications != null) {
      _subscriptions.add(notifications.taps.listen(_followTap));
    }
  }

  /// Cancels subscriptions and releases the underlying router.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final subscriptions = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    refreshListenable?.dispose();
    router.dispose();
  }

  void _followUri(Uri uri) {
    _followLocation(deepLinkMapper.map(uri));
  }

  void _followTap(NotificationTap tap) {
    _followLocation(notificationMapper.map(tap));
  }

  void _followLocation(String? location) {
    if (location == null || _disposed) {
      return;
    }
    final target = Uri.parse(location);
    if (router.routerDelegate.currentConfiguration.uri == target) {
      return;
    }
    router.go(location);
  }
}

class _SignInPage extends StatelessWidget {
  const _SignInPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('sign-in-page'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_outline_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text('Masuk', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Silakan masuk untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
