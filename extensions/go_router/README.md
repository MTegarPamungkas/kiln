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
- `route_transitions.dart` supplies page transitions as data; screens stay in
  the application.
- `SignInPageBuilder` supplies the application sign-in page. Enabling the auth
  redirect requires it.
- `AppRouterConfig.errorBuilder` supplies the application not found page.

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

## Sign-in page and errors

Register `SignInPageBuilder` to render the app's login screen on `/sign-in` and
enable the guard explicitly, because auth policy and UI are app-owned:

```dart
registry.registerSingleton<SignInPageBuilder>(const AppSignInPage());
registry.registerSingleton<AppRouterConfig>(
  const AppRouterConfig(
    enableAuthRedirect: true,
    errorBuilder: (context, state) => const AppErrorPage(),
  ),
);
```

The extension ships no sign-in page, shell, or not found page. Without a
`SignInPageBuilder`, `enableAuthRedirect` throws during router creation.

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
