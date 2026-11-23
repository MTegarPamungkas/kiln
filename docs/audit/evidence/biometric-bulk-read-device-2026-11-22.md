# Biometric bulk-read device acceptance

Date: 2026-11-22. Physical phone `c7d2692b` (Xiaomi M2007J20CG, Android 13,
API 33), one fingerprint enrolled. Not an emulator run. No commit or deployment
was made.

## Result

**K06** now has the two live device checks its unit tests could not cover:
a cancelled challenge leaks nothing, and a successful bulk read authenticates
exactly once.

| Check | Outcome |
| --- | --- |
| Probe support | `supported`; enrolled methods `weak, strong` |
| `readAll` with the prompt cancelled (BACK) | `Failure(cancelled, cancelled)`; no values returned |
| `readAll` with a successful scan | returned both seeded values (`probe.alpha`, `probe.beta`) |
| Authentication count for that bulk read | device fingerprint counter `accept` went 23 → 24, i.e. one prompt for two keys |

The wrapper reads without auth only for write/delete/clear, which is the
documented policy: `read` and `readAll` both authenticate, and the failure is
typed (`cancelled`) rather than a raw platform exception.

## Fixture

`tool/e2e/device_probe.dart --biometric` renders the current `biometric` and
`secure_storage` bricks into `.dart_tool/biometric_probe`, applies their native
manifest patches (host activity switched to `FlutterFragmentActivity`, since
biometric prompts need it), and writes `tool/e2e/biometric_probe_main.dart.tmpl`
as `lib/main.dart`. The probe seeds two values with unauthenticated `write`,
then performs one `readAll`, logging one `KILNPROBE` line per result.

```bash
dart run tool/e2e/device_probe.dart --biometric
cd .dart_tool/biometric_probe && flutter build apk --debug
adb -s c7d2692b install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s c7d2692b shell am start -n dev.kiln.biometric_probe/.MainActivity
```

## How each path was driven

The prompt is a system `BiometricPrompt` window. Cancellation was sent without
touching the device UI:

```bash
adb -s c7d2692b shell dumpsys window | grep mCurrentFocus   # BiometricPrompt
adb -s c7d2692b shell input keyevent KEYCODE_BACK
```

The successful path waited for a physical scan on the sensor; the prompt count
was read afterwards from the platform's own counter:

```bash
adb -s c7d2692b shell dumpsys fingerprint | grep -o '"prints":\[[^]]*\]'
# accept: 23 before the run, 24 after a single bulk read of two keys
```

## Not-enrolled path (guest user) — found a defect

The not-enrolled branch was reached without removing the owner's fingerprints by
creating a disposable Android guest user (user 10, no fingerprints, no
screen-lock credential) and installing the probe into it only:

```bash
adb shell pm create-user --guest "kiln probe"   # -> user 10
adb shell am start-user -w 10
adb install --user 10 build/app/outputs/flutter-apk/app-debug.apk
adb shell am switch-user 10
adb shell am start --user 10 -n dev.kiln.biometric_probe/.MainActivity
```

The first build reported the wrong state:

```
KILNPROBE support biometric unsupportedDevice This device has no biometric hardware.
KILNPROBE enrolled
KILNPROBE readAll_failure support.unsupported_device unsupported
```

**Cause:** `Biometric.availability()` used `isDeviceSupported()` as the hardware
signal. On Android that is `isDeviceSecure || canAuthenticateWithBiometrics()`,
which is false for a profile with no screen lock and true for a
pin-only device. `canCheckBiometrics()` is the real hardware probe
(`deviceCanSupportBiometrics`).

**Fix:** `availability()` probes `canCheckBiometrics()` for hardware, falls back
to `isDeviceSupported()` only when that is false, and skips enumerating methods
without hardware. Hardware with no enrollment now resolves to `notEnrolled` →
`permissionDenied`; only a false hardware probe gives `unsupportedDevice`.
Regression tests cover both branches; `app_lock_test` now clears the hardware
probe in its "no biometrics" case instead of only `supported`.

The fix was confirmed on the same guest user. The corrected build reports:

```
KILNPROBE support biometric permissionDenied Biometrics are not enrolled on this device.
KILNPROBE enrolled
KILNPROBE seeded
KILNPROBE readAll_failure permission.denied permission
```

So the state is now `notEnrolled` → `permissionDenied`, and the bulk read fails
closed with no values.

The guest user was removed after the run (`pm remove-user 10`); the owner
profile's fingerprint enrollment was unchanged before and after
(`"id":0,"count":1`), and no owner data was modified.

## What this closes and what stays open

- **K06**: denied/cancelled bulk read yields no values, and a successful bulk
  read authenticates once — both observed on hardware. The not-enrolled path
  exposed a real misclassification (`unsupportedDevice` for hardware present with
  nothing enrolled), which is fixed and re-verified on the guest user
  (`permissionDenied`, read fails closed). The lockout path remains unexercised.
- **K07** stays iOS-only: it needs a real Keychain with custom
  service/access-group options, which requires an iPhone.
- **K28** is unaffected by this run; plugin-level picker acceptance (including
  HEIC) still needs a device run, and HEIC needs an iPhone.

## Isolation and cleanup

Only debug builds of disposable fixtures were installed on the owner's test
phone. No credential, permission, or system setting was changed for this run;
the fingerprint enrollment was used, not modified. Nothing was written outside
`.dart_tool/`.
