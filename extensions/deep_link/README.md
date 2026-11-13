# deep_link

Implementation of `DeepLinks` from `kiln_core` on top of the `app_links` plugin.

- `DeviceDeepLinks` captures the launch link after `start()` and forwards
  incoming links to the listener.
- `LinkAllowlist` rejects schemes and hosts that are not configured, including
  per-segment path prefix matching.
- `LinkNormalizer` lowercases the scheme and host, tidies the path, strips
  tracking parameters, and removes the fragment.
- `LinkDeduplicator` ignores the same link within the time window from
  `Clock`.
- `PendingLinkBuffer` stores links that arrive before the first listener is
  attached, then replays them once.
- `AppLinkBuilder` builds outgoing links with the project scheme or a universal
  link.
- Plugin errors are converted into `Failure(deep_link, kind: deepLink)` by
  `mapDeepLinkError`.

## How to install

```bash
kiln add deep_link
```

Available prompts:

| Prompt | Content | Default |
| --- | --- | --- |
| `scheme` | custom scheme without `://` | `kiln` |
| `hosts` | allowed universal link hosts | `kiln.dev` |
| `path_prefixes` | allowed path prefixes for universal links | empty |

`hosts` and `path_prefixes` are of type `multi`, so the choices are taken from
`options` in `extension.yaml`. Add your host or prefix to `options` before
running `kiln add` if it is not listed yet.

## Configuration

Runtime settings live in `DeepLinkConfig`. Default values are rendered from the
prompts; normalization options can be changed through the constructor:

```dart
const config = DeepLinkConfig(
  scheme: 'kiln',
  allowedHosts: <String>['kiln.dev'],
  pathPrefixes: <String>['/app'],
  stripTrackingParameters: true,
  dropFragment: true,
  deduplicationWindow: Duration(seconds: 2),
);
```

## Usage

```dart
final deepLinks = registry.read<DeepLinks>();

final subscription = deepLinks.links.listen((link) {
  router.go(link.path);
});

final initial = deepLinks.initialLink;
if (initial != null) {
  router.go(initial.path);
}
```

`DeepLinkModule.ready` calls `start()` automatically during bootstrap, so the
listener can be attached at any time: links that arrive earlier are stored and
replayed once.

The launch link is not sent to `links`; read `initialLink` so that navigation
does not happen twice.

## Important limits

- The native custom scheme follows the `scheme` prompt through
  `url_scheme_prompt`, on Android, iOS, and macOS. The host lists in
  `extension.yaml` are still static; update `android.app_links.hosts` and
  `ios.associated_domains` when the `hosts` prompt changes, then reinstall.
- Only the configured custom scheme and `https` are accepted; `http` is
  rejected.
- If `hosts` is empty, every `https` link is rejected and only the custom scheme
  works.
- If `path_prefixes` is empty, all paths on the allowed hosts are accepted.

Further guides:

- [docs/deep-links.md](docs/deep-links.md)
- [docs/universal-links.md](docs/universal-links.md)
- [docs/testing-links.md](docs/testing-links.md)

## Gate

```dart
import 'package:my_app/extensions/deep_link/gate_deep_link.dart';

final initial = gate.deepLinks.initialLink;   // Uri?
gate.deepLinks.links.listen((uri) { ... });   // Stream<Uri>

final link = await gate.buildCustomLink('/profile/42');   // Result<Uri>
final web = await gate.buildUniversalLink('/app/home');   // Result<Uri>
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
