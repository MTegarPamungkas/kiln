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
- `SignInPageBuilder` replaces the built-in sign-in page while keeping the auth
  guard.
- `AppRouterConfig.includeSampleShell` removes the starter `/` and `/explore`
  routes so the application can own those paths.

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

Routes must be contributed before `GoRouterModule.register` builds the router.
List the application module before the generated modules:

```dart
KilnBootstrap.run(
  modules: <KilnModule>[const AppModule(), ...kilnModules()],
);
```

Do not require the `navigation` capability from a module that contributes
routes: required capabilities are registered first, so the router would be
built before those routes exist.

## Replacing the sign-in page and starter shell

Register `SignInPageBuilder` to keep `AuthRedirect` but render the app's login
screen on `/sign-in`:

```dart
registry.registerSingleton<SignInPageBuilder>(const AppSignInPage());
```

Register `AppRouterConfig(includeSampleShell: false)` to drop the starter
two-tab shell, then contribute the app's own `/` route through the slot.

## Navigating from a widget

```dart
context.go('/orders/42');
context.push('/orders/42');
context.pop();
```

The full guide is in [docs/navigation.md](docs/navigation.md),
[docs/route-guards.md](docs/route-guards.md), and
[docs/deep-links-and-routing.md](docs/deep-links-and-routing.md).
