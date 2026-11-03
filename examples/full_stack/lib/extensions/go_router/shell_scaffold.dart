import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Bottom navigation shell used by the sample tabs.
///
/// The shell reads the active location from [GoRouterState.uri] instead of
/// keeping local state, so deep links and browser history stay in sync.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    required this.location,
    required this.child,
    super.key,
  });

  /// Path of the active nested route, for example `/explore`.
  final String location;

  /// Nested navigator content for the active tab.
  final Widget child;

  static const Key navigationBarKey = Key('shell-navigation-bar');

  @override
  Widget build(BuildContext context) {
    final selectedIndex = location == AppRoutes.explore ? 1 : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        key: navigationBarKey,
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          final target = index == 0 ? AppRoutes.home : AppRoutes.explore;
          if (target != location) {
            context.go(target);
          }
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Jelajahi',
          ),
        ],
      ),
    );
  }
}

/// Builds the sample [ShellRoute] with its two tabs.
///
/// Replace the tab routes with application features, or remove the shell from
/// `AppRouter` and register a top-level route for each tab instead.
ShellRoute buildShellRoute() {
  return ShellRoute(
    builder: (BuildContext context, GoRouterState state, Widget child) {
      return ShellScaffold(location: state.uri.path, child: child);
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (BuildContext context, GoRouterState state) =>
            const _HomeTab(),
      ),
      GoRoute(
        path: AppRoutes.explore,
        name: AppRoutes.exploreName,
        builder: (BuildContext context, GoRouterState state) =>
            const _ExploreTab(),
      ),
    ],
  );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Halaman Beranda', key: Key('home-tab')),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Halaman Jelajahi', key: Key('explore-tab')),
    );
  }
}
