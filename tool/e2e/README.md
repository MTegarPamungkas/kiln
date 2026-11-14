# End-to-end extension run

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

- `appwrite`, `firebase`, `neon`, `supabase` are left out on purpose, they are
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
