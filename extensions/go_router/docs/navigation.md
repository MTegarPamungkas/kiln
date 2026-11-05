# Navigation

## What is registered

`GoRouterModule` registers three things in the Registry:

| Type | Contents |
| --- | --- |
| `RouterConfig<Object>` | The `GoRouter` instance read by `AppShell` |
| `AppRouter` | Owner of the router, observer, and link integration |
| `AppRouterConfig` | Initial location, diagnostics, error builder, observers, sample shell and auth redirect switches |

The `router.routes` slot is opened by the module. Slot items are of type
`AppRoute` from `app_basic`, so features do not need to depend on `go_router`.

## Default routes

`AppRoutes` holds the default locations:

- `/` with the name `home`
- `/sign-in` with the name `signIn`

`/sign-in` is registered only when the application registers a
`SignInPageBuilder`. With the defaults the router resolves only the routes the
application contributes, which keeps auth policy and navigation structure in
the app.

Claim `/` by contributing a route through the slot:

```dart
registry.read<SlotRegistry>().open<AppRoute>(SlotNames.routerRoutes).add(
  AppRoute(
    path: '/',
    name: 'appHome',
    builder: (context) => const DashboardPage(),
  ),
);
```

## Custom sign-in page

`SignInPageBuilder` supplies the sign-in page when `enableAuthRedirect` is on.
Register both before `GoRouterModule.register`:

```dart
final class AppSignInPage implements SignInPageBuilder {
  const AppSignInPage();

  @override
  Widget build(BuildContext context) => const LoginPage();
}

registry
  ..registerSingleton<SignInPageBuilder>(const AppSignInPage())
  ..registerSingleton<AppRouterConfig>(
    const AppRouterConfig(enableAuthRedirect: true),
  );
```

When no builder is registered, `AppRouter` falls back to the built-in
`_SignInPage`.

## Adding routes through a slot

```dart
registry
    .read<SlotRegistry>()
    .open<AppRoute>(SlotNames.routerRoutes)
    .add(
      AppRoute(
        path: '/orders/:id',
        name: 'order',
        builder: (context) => const OrderDetailPage(),
      ),
    );
```

`RouteSlot` turns each `AppRoute` into a `GoRoute` with the same path, name, and
builder. Item order follows slot priority, then insertion order.

Contribute routes before `GoRouterModule.register` builds the router. When the
application supplies its own module, list it before the generated modules:

```dart
KilnBootstrap.run(
  modules: <KilnModule>[const AppModule(), ...kilnModules()],
);
```

Do not declare `navigation` as a required capability on a route-contributing
module: required capabilities are initialized first, so `GoRouterModule` would
build the router before the routes exist. `navigation` is useful only for
modules that consume the router after registration.

Path parameters can be read from `GoRouterState` inside the builder:

```dart
AppRoute(
  path: '/orders/:id',
  name: 'order',
  builder: (context) => OrderDetailPage(
    orderId: GoRouterState.of(context).pathParameters['id']!,
  ),
);
```

## Navigation

Inside a widget below `MaterialApp.router`, use the extension from `go_router`:

```dart
context.go('/orders/42');
context.pushNamed('order', pathParameters: {'id': '42'});
context.pop();
```

Outside the widget tree, for example from a controller, use
`registry.read<AppRouter>().router`.

## Transitions

`buildRoutePage` in `route_transitions.dart` selects a transition per platform:
slide for iOS and macOS, fade with a small slide for Android, and fade for
Windows and Linux. The default `/sign-in` route uses it. Use the same function
in `pageBuilder` for routes that need a custom animation.

## Configuration

```dart
final config = AppRouterConfig(
  initialLocation: '/explore',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => const AppErrorPage(),
);
```

The application supplies `errorBuilder`; the extension does not ship an error
screen. When it is omitted, go_router renders its own default error page. Do
not enable `debugLogDiagnostics` in release builds.
