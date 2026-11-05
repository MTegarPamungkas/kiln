# Route guards

## Interface

A guard is a synchronous redirect rule evaluated before a route is shown:

```dart
abstract interface class RouteGuard {
  String? redirect(RouteGuardContext context);
}
```

`RouteGuardContext` carries `location`, `name`, and `isAuthenticated`. A guard
must not call `go` or `push` itself; just return the destination location. A
`null` value means this guard has no objection and evaluation continues.

## Order

`evaluateRouteGuards` runs guards in composition order and stops at the first
redirect:

```dart
final guards = <RouteGuard>[
  MaintenanceGuard(config),
  const AuthRedirect(),
];
```

A guard that returns the same location is treated as not redirecting, so no
loop occurs. Slow guards should read data that is already available; router
redirects do not wait for network work.

## AuthRedirect

`AppRouter` adds `AuthRedirect` automatically when a `SessionController` is
registered:

- Not signed in on another route: redirected to `/sign-in`.
- Not signed in on `/sign-in`: left alone.
- Signed in on `/sign-in`: redirected to `/`.
- Signed in on another route: left alone.

An `unknown` status is treated as not signed in. Session restoration must finish
before the first UI is shown, or the app will stop at `/sign-in` first.

## Refresh when the session changes

`SessionRefreshListenable` forwards `SessionController.changes` to the
`refreshListenable` of `GoRouter`. When the user signs in or out, go_router
re-evaluates redirects without rebuilding the whole app. This listenable is
disposed together with the router in `AppRouter.dispose`.

## Custom guards

Add guards through the `AppRouter` constructor:

```dart
final router = AppRouter(
  registry: registry,
  guards: <RouteGuard>[
    MaintenanceGuard(registry.read<Env>()),
    RoleGuard(requiredRole: 'admin'),
  ],
);
```

Extra guards run after the built-in guards. To change the sign-in behavior,
replace `AuthRedirect` in `AppRouter` or provide a guard that handles that
location before the built-in guards.
