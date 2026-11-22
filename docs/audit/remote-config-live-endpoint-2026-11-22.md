# Remote config against a live endpoint

Date: 2026-11-22 (Asia/Jakarta). Closes the "live endpoint" remainder of K16: the
suite previously used only a fake gateway, so the transport and decoding path
between `package:http` and the client's snapshot rules was untested. No commit
was made.

The endpoint is a loopback server started by the test, not a vendor endpoint.
That makes the run reproducible and credential-free; a vendor endpoint would test
the same client code with a different host. The report says "live" in the sense
that a real socket, real HTTP status codes and real timeouts are involved.

## What runs

`extensions/remote_config/brick/__brick__/test/extensions/remote_config/remote_config_live_endpoint_test.dart`
starts an `HttpServer` on `127.0.0.1:0` and uses the real `HttpRemoteConfigGateway`.
It is not gated by an environment flag, because it needs no endpoint or secret;
it finishes in about a second.

| Test | What it proves |
| --- | --- |
| bootstrap fetches and activates over a real socket | `KilnBootstrap.run` reaches the module's support probe, the probe fetch is reused by `ready`, and the values become readable. One HTTP request, correct path. |
| a superseded slow response cannot become active | A response held in flight while a second `fetch()` starts is discarded by the generation guard; the newer value is active. |
| HTTP 500 maps to a typed failure and keeps the active values | A failing refresh throws `Failure(unavailable)` and does not clear the active snapshot. |
| a slow endpoint produces `network.timeout` | `requestTimeout` maps to the typed timeout failure; the client still closes cleanly. |
| a non-JSON body produces `validation.invalid_input` | Decode failures are typed, not raw `FormatException`s. |
| an unreachable endpoint degrades to defaults, not a failed boot | Bootstrap succeeds, reads fall back to caller defaults, and the support state is `unavailable`. |

## Result

```
dart run tool/verify_extensions.dart --only remote_config --update
dart run tool/verify_extensions.dart --only remote_config --analyze --test
```

`analyzed remote_config` + `tested remote_config`, no failures. The rendered
golden includes the new test file, and the extension lint stays green.

Two details worth keeping:

- `kiln_core` exports its own `HttpRequest` contract, so the test hides it:
  `import 'package:kiln_core/kiln_core.dart' hide HttpRequest;`. Without the hide,
  the analyzer resolves `dart:io`'s request as the Kiln type.
- The test server swallows writes to a socket the client already closed, so the
  timeout test does not race the delayed response.

## Still open

`RemoteConfigConfig.fetchInterval` is documented as a suggested cadence, but
nothing schedules refreshes: the app calls `fetch`/`fetchAndActivate` itself. That
is a product decision (in-app timer versus app-owned scheduling versus OS
background work), not a defect found by this pass. A vendor endpoint can be
plugged into the same test by changing the endpoint URL if one is available.
