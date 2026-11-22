# End-to-end extension run

For the minimal Android/web Appwrite auth + in-memory backend probe, see
[the functional run and reproduction guide](../../docs/audit/android-web-auth-2026-11-19.md).
It exercises actual auth/JWT/session persistence while keeping backend CRUD in
memory; it does not provision an Appwrite database or bucket.

> For automated live-server testing, the `appwrite` extension ships a
> provisioning tool and contract-driven e2e suite; see
> [`extensions/appwrite/docs/e2e-testing.md`](../../extensions/appwrite/docs/e2e-testing.md).
> This template remains a minimal copy-in probe screen for device runs.

`e2e_page.dart.tmpl` is the screen used to exercise every Kiln extension on a
real device. It is not part of any package: copy it into a generated app, then
run that app on a phone or emulator.

## Build the run app

```bash
kiln create kiln_e2e --org dev.kiln \
  --with analytics,biometric,bloc,calendar,codegen,connectivity,crash_report,\
deep_link,dio,env,flavors,geolocation,go_router,http_cache,http_retry,\
image_picker,l10n,local_db,logger,notifications,permission,rest_auth,\
secure_storage,share,storage,theme \
  --answer codegen.generators=json_serializable,freezed \
  --answer deep_link.scheme=kiln \
  --answer dio.base_url=https://jsonplaceholder.typicode.com \
  --answer rest_auth.base_url=https://jsonplaceholder.typicode.com \
  --yes
```

Twenty-six extensions is the widest set that installs together:

- `appwrite`, `firebase`, `supabase` are left out on purpose, they are
  alternative backends for the same capabilities.
- `riverpod` is left out because `bloc` is the state extension under test, and
  only one state provider can be installed.
- `social_login` cannot be installed: it `requires: social_auth`, which only the
  excluded backends provide.
- `remote_config` can be added to this set; it is no longer exclusive with
  `env`. This template does not include a remote-config probe.

## Copy the screen in

```bash
mkdir -p lib/features/e2e/presentation/screens
cp <kiln>/tool/e2e/e2e_page.dart.tmpl lib/features/e2e/presentation/screens/e2e_page.dart
```

Then point the app at it. With `go_router` installed the router owns the tree,
so the root route in `lib/app/app_routes_module.dart` is what has to change:

```dart
import '../features/e2e/presentation/screens/e2e_page.dart';

// inside AppRoutesModule.register
routes.add(AppRoute(path: '/', name: 'home', builder: (_) => const E2ePage()));
```

Without `go_router`, pass it as the home page in `lib/main.dart`
(`home: const E2ePage()`).

## Run it

```bash
flutter run -d emulator-5554
```

The screen runs every probe on first frame and prints one line per extension
with `developer.log(name: 'kiln_e2e')`, so the same report can be read with
`adb logcat -s flutter`.

## Result of the reference run

Pixel 10a emulator, API 36, all 26 probes reached the device:
**26 ok / 0 failed**. Device-dependent outcomes are expected, not failures:

| Probe | Outcome on the emulator |
| --- | --- |
| analytics | event captured; `support: notConfigured` without a PostHog key |
| biometric | `unsupportedDevice`: the emulator has no biometric hardware |
| bloc | cubit state reaches 2, `flutter_bloc` wired |
| calendar | `addEvent` returns false: no calendar app on the emulator |
| codegen | freezed + json_serializable round trip keeps values |
| connectivity | `status=online` |
| crash_report | message and breadcrumb accepted; `notConfigured` without a DSN |
| deep_link | `kilnapp://e2e?p=1` and the https link are built from the answer |
| dio | real GET to jsonplaceholder returns 200 |
| env | four keys read from the generated schema |
| flavors | `notConfigured` when no flavor is registered |
| geolocation | location service reported disabled |
| go_router | current location is `/` |
| http_cache | entry written, read back and reported fresh |
| http_retry | policy supported |
| image_picker | picker supported for both sources |
| l10n | locale switches to `id` and back to system |
| local_db | document written, read back and deleted |
| logger | record reaches the memory sink |
| notifications | supported |
| permission | camera reported `denied`, no prompt raised |
| rest_auth | sign-in failure mapped to `Failure(unavailable)` |
| secure_storage | value written, read, deleted |
| share | supported |
| storage | value written, read, deleted |
| theme | mode switches dark and back to system |

## What the first run caught

Every fix below came out of building this app, not out of reading the code:

1. `codegen` pinned `build_runner ^2.17.1` and `freezed ^4.0.3`, which need
   `analyzer 14`; `flutter_test` in this SDK pins `test_api 0.7.12`, so
   `flutter pub get` failed for any app that used codegen.
2. `kiln_testing` required `test ^1.31.1`, which no `test` release can satisfy
   next to that same `flutter_test` pin.
3. `crash_report` did not raise the Android `minSdk`, and `sentry_flutter`
   declares 26, so `flutter build apk` failed at the manifest merger.
4. the `deep_link` brick tests hardcoded the default scheme, so two generated
   tests failed as soon as the install answer differed.
5. the minimal app template ignored its home page when `go_router` was
   installed: the router only sees routes contributed to `router.routes` before
   it is built, so the app opened on `GoException: no routes for location: /`.
6. the `crash_report` and `dio` bricks shipped four analyzer findings into every
   generated app.

## Dio + HTTP cache composition

`dio_cache_probe.dart` renders the `dio` and `http_cache` bricks into one project
and runs `dio_cache_composition_test.dart.template` against a loopback HTTP
server: cached repeat reads, `no-store`, mutation invalidation, `Range` bypass and
`If-None-Match` revalidation, using the real transport, pipeline and cache
middleware rather than fakes.

```bash
dart run tool/e2e/dio_cache_probe.dart
```

It needs no credentials; the fixture lands in `.dart_tool/dio_cache_probe`.

## Push routing probe host

`push_routing_host.mjs` is the loopback fixture the `--routing` probe needs. The
rendered probe has no embedded credentials: it fetches its Appwrite endpoint,
project, push endpoint and temporary-account values from `GET /fixture`, then
posts progress to `POST /report`. This host owns that exchange, keeps the server
API key in memory, can confirm which account the app is actually signed in as, and
can send uniquely labelled probe messages.

```powershell
$env:KILN_APPWRITE_ENDPOINT = 'https://appwrite.example/v1'
$env:KILN_APPWRITE_PROJECT  = '<project id>'
$env:KILN_APPWRITE_API_KEY  = '<server API key>'
$env:KILN_APPWRITE_PUSH_ENDPOINT = 'mqtts://push.example:8883'
$env:KILN_ROUTING_USER      = '<disposable user id>'
node tool/e2e/push_routing_host.mjs --port 8768
adb -s <serial> reverse tcp:8768 tcp:8768
```

Routes:

| Route | Purpose |
| --- | --- |
| `GET /fixture?platform=android` | Probe configuration and temporary-account values. |
| `POST /report` | Probe progress; appended to `<state-dir>/reports.jsonl`. |
| `GET /reports` | All recorded reports. |
| `GET /admin/user` | Account lookup proving the signed-in identity. |
| `GET /admin/users?search=` | Find a user by email. |
| `POST /admin/send` | Send a labelled push: `{title, body, data:{route}}`. |
| `GET /admin/message?id=` | Delivery status for one message. |
| `POST /admin/push-endpoint` | Point the next probe launch at another broker: `{endpoint}`. |

Defaults: port 8768 and state under `.dart_tool/push_routing_host/` (reports,
log, and an optional `password.txt`). `--reset-password` regenerates the
disposable user's password through the server API when it has been lost; only use
it on a throwaway test user this run owns. The key, passwords and tokens are never
written into the repository or the log. The host must be running before the probe
is relaunched, otherwise the app reports a startup failure.

For the device acceptance procedure and recorded results, see
[the push routing report](../../docs/audit/appwrite-push-routing-2026-11-20.md).

## Supabase local RLS and browser OAuth

Four fixtures cover the Supabase acceptance pass; none needs a third-party
account:

| File | Role |
| --- | --- |
| `supabase_rls_schema.sql` | Acceptance schema: owner-only `notes`, public-read `public_notes`. |
| `supabase_local_rls_probe.dart` | Signs up two users and asserts the RLS matrix (16 checks). |
| `supabase_mock_oidc.mjs` | Local OIDC provider registered as GoTrue's `keycloak` provider. |
| `serve_supabase_oauth_app.mjs` | Serves the probe app and records its event reports. |
| `run_supabase_oauth.mjs` | Playwright driver for the browser OAuth run (15 checks). |

```powershell
# stack, schema and RLS matrix
supabase start
docker exec -i supabase_db_<project> psql -U postgres -v ON_ERROR_STOP=1 `
  < tool/e2e/supabase_rls_schema.sql
$env:KILN_SUPABASE_URL = 'http://127.0.0.1:54321'
$env:KILN_SUPABASE_ANON_KEY = '<anon key>'
dart run tool/e2e/supabase_local_rls_probe.dart

# browser OAuth (see the report for the config.toml provider block)
node tool/e2e/supabase_mock_oidc.mjs --port 8771 --issuer http://<host-lan-ip>:8771
node tool/e2e/serve_supabase_oauth_app.mjs --port 8088
node tool/e2e/run_supabase_oauth.mjs
```

GoTrue runs in Docker, so the provider URL must be an address the container can
reach and the browser can open; `127.0.0.1` is the container itself. The mock
binds `0.0.0.0` and its `--issuer` must equal the configured provider URL.

Procedure and recorded results:
[the Supabase local RLS and browser OAuth report](../../docs/audit/supabase-local-rls-2026-11-22.md).
