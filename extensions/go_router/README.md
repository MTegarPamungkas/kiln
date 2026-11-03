# go_router

Declarative navigation for Kiln apps on top of `go_router`. This extension
fills the `RouterConfig<Object>` seam read by `app_shell.dart`, so
`app.dart` does not need to be edited.

- `GoRouterModule` registers `RouterConfig<Object>`, `AppRouter`, and
  `AppRouterConfig`, then opens the `router.routes` slot.
- `AppRouter` builds `GoRouter` from the initial location, slot routes, guards,
  and `SessionController`.
- `AuthRedirect` sends visitors who are not signed in to `/sign-in` and
  moves visitors who are signed in away from that page.
- `DeepLinkRouteMapper` and `NotificationRouteMapper` turn incoming links and
  notification payloads into route locations.
- `NavigationObserver` logs navigation to `AppLogger` and sends screens to
  `Analytics` when the contract is available.
- `NotFoundPage`, `ShellScaffold`, and `route_transitions.dart` provide starter
  UI that the app can replace.

## Install

```bash
kiln ext add go_router
```

This extension is `exclusive` for the navigation category and provides the
`navigation` capability. `deep_links`, `notifications`, `analytics`, and `logger` are
optional; their integration activates automatically when the contracts are registered in the Registry.

## Adding a route

Other features do not need to import `go_router`. Just contribute an `AppRoute`
from `app_basic` to the `router.routes` slot:

```dart
final slots = registry.read<SlotRegistry>();
slots.open<AppRoute>(SlotNames.routerRoutes).add(
  AppRoute(
    path: '/orders/:id',
    name: 'order',
    builder: (context) => const OrderDetailPage(),
  ),
);
```

Routes must be contributed before `GoRouterModule.register` runs.
Modules that provide routes can declare the `navigation` capability
as a dependency so that the order is correct.

## Navigating from a widget

```dart
context.go('/orders/42');
context.push('/orders/42');
context.pop();
```

The full guide is in [docs/navigation.md](docs/navigation.md),
[docs/route-guards.md](docs/route-guards.md), and
[docs/deep-links-and-routing.md](docs/deep-links-and-routing.md).
