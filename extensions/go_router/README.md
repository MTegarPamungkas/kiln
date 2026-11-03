# go_router

Declarative navigation for Kiln apps on top of `go_router`. This extension
fills the `RouterConfig<Object>` seam read by `app_shell.dart`, so
`app.dart` does not need to be edited.

- `GoRouterModule` registers `RouterConfig<Object>`, `AppRouter`, and
  `AppRouterConfig`, then opens the `router.routes` slot.
- `AppRouter` builds `GoRouter` from the initial location, slot routes, guards,
  and `SessionController`.
- `AuthRedirect` is available for apps that want a login wall; enable it with
  `AppRouterConfig(enableAuthRedirect: true)`.
- `DeepLinkRouteMapper` and `NotificationRouteMapper` turn incoming links and
  notification payloads into route locations.
- `NavigationObserver` logs navigation to `AppLogger` and sends screens to
  `Analytics` when the contract is available.
- `NotFoundPage`, `ShellScaffold`, and `route_transitions.dart` provide optional
  starter UI. The sample shell is off by default.
- `SignInPageBuilder` replaces the built-in sign-in page while keeping the auth
  guard.
- `AppRouterConfig.includeSampleShell` adds the starter `/` and `/explore`
  routes when an app explicitly wants the demo shell.

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

Register `SignInPageBuilder` to render the app's login screen on `/sign-in` and
turn on the guard explicitly, because auth policy is app-owned:

```dart
registry.registerSingleton<SignInPageBuilder>(const AppSignInPage());
registry.registerSingleton<AppRouterConfig>(
  const AppRouterConfig(enableAuthRedirect: true),
);
```

`includeSampleShell` defaults to `false`. Set it to `true` only when you want
the starter two-tab demo; otherwise contribute the app's own `/` route through
the slot.

## Navigating from a widget

```dart
context.go('/orders/42');
context.push('/orders/42');
context.pop();
```

The full guide is in [docs/navigation.md](docs/navigation.md),
[docs/route-guards.md](docs/route-guards.md), and
[docs/deep-links-and-routing.md](docs/deep-links-and-routing.md).

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
