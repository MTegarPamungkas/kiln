# Navigation

## What is registered

`GoRouterModule` registers three things in the Registry:

| Type | Contents |
| --- | --- |
| `RouterConfig<Object>` | The `GoRouter` instance read by `AppShell` |
| `AppRouter` | Owner of the router, observer, and link integration |
| `AppRouterConfig` | Initial location, diagnostic logging, error builder, extra observers |

The `router.routes` slot is opened by the module. Slot items are of type
`AppRoute` from `app_basic`, so features do not need to depend on `go_router`.

## Default routes

`AppRoutes` holds the extension's route paths and names:

- `/` with the name `home`
- `/explore` with the name `explore`
- `/sign-in` with the name `signIn`

`/` and `/explore` live inside a `ShellRoute` with a `NavigationBar`.
`/sign-in` lives outside the shell so it does not show the bottom navigation.

Replace the contents of `_HomeTab` and `_ExploreTab` in `shell_scaffold.dart`,
or replace the whole `buildShellRoute()` with the app's routes. If the shell is
not used, remove the `buildShellRoute()` call from `AppRouter` and register the
tab routes directly.

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

If `errorBuilder` is not set, `NotFoundPage` is displayed. Do not enable
`debugLogDiagnostics` in release builds.
