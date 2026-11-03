# Deep links

This extension provides the `DeepLinks` contract from `kiln_core`. There are two
kinds of link handled:

1. Custom schemes, for example `kiln://profile/42`.
2. Universal links `https://kiln.dev/profile/42` on Android and iOS.

Both arrive through `app_links`, are normalized, filtered, and then forwarded to
the application.

## Processing flow

```text
app_links -> LinkNormalizer -> LinkAllowlist -> LinkDeduplicator -> links
```

- `LinkNormalizer` lowercases the scheme and host, removes default ports,
  collapses double slashes, strips the trailing slash from the path, drops
  tracking parameters (`utm_*`, `fbclid`, and similar), and removes the
  fragment.
- `LinkAllowlist` accepts the configured custom schemes and `https` only for
  hosts listed in `allowedHosts`. Path prefixes are matched per segment, so
  `/app` accepts `/app/42` but rejects `/application`.
- `LinkDeduplicator` uses a `Clock`, so the duplicate window can be tested with
  `FixedClock`.

## Lifecycle

```dart
final deepLinks = DeviceDeepLinks(
  gateway: SdkAppLinksGateway(),
  config: DeepLinkConfig.defaults,
  clock: registry.read<Clock>(),
);

await deepLinks.start();
final subscription = deepLinks.links.listen(handleLink);

final initial = deepLinks.initialLink;
if (initial != null) {
  handleLink(initial);
}
```

`start()` is idempotent. Links that arrive before the first listener is attached
are stored in `PendingLinkBuffer` and replayed once when the listener attaches.
The launch link is only available through `initialLink`; the same link is not
delivered twice because of deduplication.

`dispose()` cancels the gateway subscription, closes the stream, and stops
forwarding new links.

## Errors

`mapDeepLinkError` turns plugin errors into
`Failure(FailureCode.deepLinkUnavailable, kind: deepLink)` and
`FormatException` into `FailureCode.deepLinkInvalid`. `DeviceDeepLinks` stores
the last error in `lastFailure`; links rejected by the allowlist are ignored
without an error.

## Router integration

```dart
final subscription = deepLinks.links.listen((link) {
  final route = link.path.isEmpty ? '/' : link.path;
  final query = link.queryParameters;
  router.go(Uri(path: route, queryParameters: query).toString());
});
```

For custom scheme links, the first segment becomes the URI host.
`kiln://profile/42` has `host == 'profile'` and `path == '/42'`, so the
application needs to map that host to a route, for example:

```dart
String routeFor(Uri link) {
  if (link.scheme == 'kiln') {
    return '/${link.host}${link.path}';
  }
  return link.path;
}
```

## Configuration

`DeepLinkConfig` stores the scheme, hosts, path prefixes, normalization options,
and the deduplication window. Change the normalization options by creating a new
configuration and registering it with the `Registry`; `DeepLinkModule` uses the
`DeepLinkConfig.defaults` rendered from the prompt.
