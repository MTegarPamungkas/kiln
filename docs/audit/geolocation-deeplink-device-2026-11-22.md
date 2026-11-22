# Geolocation and deep-link device acceptance

Date: 2026-11-22. Physical phone `c7d2692b` (Xiaomi M2007J20CG, Android 13,
API 33). Not an emulator run. No commit or deployment was made.

## Result

Two findings moved forward on a real device without any provider credentials:
**K26** geolocation now has device race evidence, and **K29** deep links were
delivered natively (cold and warm) with the allowlist enforced.

| Check | Outcome |
| --- | --- |
| Location service off, permission revoked | support `unavailable`, `current()` and `updates()` both `Failure(unavailable, unavailable)` |
| Location service on, permission denied | support `permissionDenied`, both calls `Failure(permission.denied, permission)` |
| Service switched off while running | ticks 1–2 `ok`, ticks 3–10 all `Failure(unavailable)`; process stayed alive |
| Service switched back on | ticks 14–17 `ok` again with no restart |
| Custom-scheme cold start | `initial_link kiln://app/profile/42` (tracking query and fragment dropped) |
| Custom-scheme warm links | `kiln://app/orders/7` delivered; `kiln://other/secret/9` dropped |
| HTTPS warm links | `https://kiln.dev/app/share/5` delivered; `evil.example` and `kiln.dev.evil.example` dropped |
| Custom-scheme cold start with traversal | `kiln://evil/../admin` → `initial_link null` |

No raw plugin exception crossed the contract: every failure above is a typed
`Failure` with a stable code. The live delivery stream also reconnected on
its own after the service returned.

## Fixture

`tool/e2e/device_probe.dart` renders the current `geolocation` and `deep_link`
bricks into `.dart_tool/device_probe` (Android only), applies the native
manifest patches from the manifests themselves (scheme `kiln`, https host
`kiln.dev`, both location permissions), and writes
`tool/e2e/device_probe_main.dart.tmpl` as `lib/main.dart`. The probe logs one
`KILNPROBE` line per result with `debugPrint`, so `adb logcat` is the report.

```bash
dart run tool/e2e/device_probe.dart
cd .dart_tool/device_probe && flutter build apk --debug
adb -s c7d2692b install -r build/app/outputs/flutter-apk/app-debug.apk
```

All prompt answers are defaults except `path_prefixes=/app`, which makes the
path boundary observable on device.

## How each state was driven

Android 13 on this ROM has no `cmd location`, so the run used
`settings put secure location_mode` (0 off / 3 on) and `pm grant` /
`pm revoke` for the permissions. `pm revoke` kills the target process, so the
mid-run *permission* race cannot be observed on this build; the mid-run
*service* race was, which is the case that proves the mapper runs per call and
not only at startup.

```bash
# service off / permission revoked
adb -s c7d2692b shell settings put secure location_mode 0
adb -s c7d2692b shell pm revoke dev.kiln.device_probe android.permission.ACCESS_FINE_LOCATION

# service on / permission denied (no hanging dialog)
adb -s c7d2692b shell pm set-permission-flags dev.kiln.device_probe \
  android.permission.ACCESS_FINE_LOCATION user-fixed

# mid-run service race
adb -s c7d2692b shell am start -n dev.kiln.device_probe/.MainActivity
adb -s c7d2692b shell settings put secure location_mode 0   # watch ticks 3..n
adb -s c7d2692b shell settings put secure location_mode 3   # watch ticks recover

# deep links
adb -s c7d2692b shell am start -a android.intent.action.VIEW -d "kiln://app/profile/42" dev.kiln.device_probe
adb -s c7d2692b shell am start -a android.intent.action.VIEW -d "kiln://other/secret/9" dev.kiln.device_probe
```

## What this closes and what stays open

- **K26**: the mapper covers synchronous, Future and stream paths on a real
  device, including a state change between calls, and recovery without
  restart. The remaining gap is the iOS permission/service race and a
  mid-run permission revoke on an Android build where `pm revoke` does not kill
  the app (none was available here; the denied-state path is covered).
- **K29**: custom-scheme links now go through the same path-prefix boundary as
  https links, and `AuthRedirect` already distinguishes `SessionStatus.unknown`
  (loading route) from signed-out, with `returnTo` sanitized. Native delivery is
  verified on Android; iOS native delivery stays open.

## Isolation and cleanup

Only a debug build of the disposable fixture was installed on the owner's test
phone; permissions were restored to granted and the location service left on
after the run. Nothing was written outside `.dart_tool/`. No credentials were
used.
