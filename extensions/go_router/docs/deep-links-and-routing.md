# Deep links and routing

## Flow

1. The `deep_link` extension registers a `DeepLinks` implementation.
2. `GoRouterModule.ready` calls `AppRouter.start()`.
3. `start()` reads `DeepLinks` and `Notifications` through `readOrNull`.
4. Each link is mapped to a location, then `router.go` is called if the
   location differs from the current location.

The read happens at `ready`, not at `register`, so providers registered after
the navigation module are still detected. If the contract is missing, the
integration is skipped without an error.

## Deep link

`DeepLinkRouteMapper` accepts URIs from `DeepLinks.initialLink` and the
`DeepLinks.links` stream.

| Link | Location |
| --- | --- |
| `https://example.com/orders/42?tab=items` | `/orders/42?tab=items` |
| `myapp://orders/42` | `/orders/42` |
| `myapp:///orders/42` | `/orders/42` |
| `myapp://explore?ref=email` | `/explore?ref=email` |
| `mailto:halo@example.com` | ignored |
| `https://example.com` | ignored |

The `mailto`, `tel`, `sms`, `file`, `javascript`, `data`, and `about` schemes
are ignored. Query and fragment are preserved because they are often used for
tracking or extra detail.

The initial link is processed before the first frame. Links that arrive while
the app is already running are processed through the stream. A link that points
to the same location does not trigger navigation again.

## Notifications

`NotificationRouteMapper` accepts a `NotificationTap` from the
`Notifications.taps` stream. The payload can be a plain route or JSON:

```text
/orders/42
{"route":"/orders/42","orderId":42}
```

Empty payloads, broken JSON, a `route` value that is not a string, and text
without a leading `/` are ignored. This extension does not import the
notifications extension; it only uses the `Notifications` and `NotificationTap`
contracts from `kiln_core`.

## Testing links

```dart
final deepLinks = FakeDeepLinks(
  initialLink: Uri.parse('https://example.com/orders/42'),
);
final registry = createTestRegistry(deepLinks: deepLinks);
final appRouter = AppRouter(registry: registry)..start();
```

Use `FakeDeepLinks.emit` and `FakeNotifications.emitTap` to test subsequent
links. Check the location with:

```dart
appRouter.router.routerDelegate.currentConfiguration.uri.path
```

## Limitations

- Only links already known to the router are displayed; the rest go to the
  application `errorBuilder`.
- Path parameters must be declared on `AppRoute.path`, for example
  `/orders/:id`.
- Deep links do not bypass guards; redirects still apply, including to
  `/sign-in` for visitors who are not signed in.
