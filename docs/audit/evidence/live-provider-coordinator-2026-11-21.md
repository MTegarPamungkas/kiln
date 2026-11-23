# Live Appwrite acceptance through the coordinator

Date: 2026-11-21 (Asia/Jakarta). No commit or deployment was made. This reruns the
live provider checks through the one-command coordinator, from a clean fixture and
the current templates, and records the harness defects that stopped it.

## Environment

- Self-hosted Appwrite `2.7.2` at the owner's project (`6afebe9d000e9c351b3e`).
- Android emulator `emulator-5554`, Android 17 (API 37).
- Chrome 157 on Windows; Flutter 3.47.9 / Dart 3.13.7.
- Fixture: `.dart_tool/appwrite_platform`, deleted before the first run so the
  scaffold and rendered sources were fresh; `dev.kiln.e2e_appwrite` was
  uninstalled before each mode.
- The server API key was supplied in the process environment only. It is not in
  the repository, reports, or logs.

## Results

Both modes completed with exit code 0 and a clean cleanup.

| Mode | Android | Web | Assertions |
| --- | ---: | ---: | ---: |
| Auth: login / restore / signed-out | 12 / 11 / 3 | 12 / 11 / 3 | 52 |
| Services: database, realtime, storage, push targets | 26 | 26 | 52 |

The auth run exercises the real account API, session persistence, restore and
logout. The services run exercises row CRUD, filters, limits, ordering, cursors,
offsets, permission denial, realtime snapshots, upload/download/replacement, a
chunked upload, signed-URL rejection and push-target lifecycle against the live
project.

`appwrite_probe_ownership.json` ended with an empty path list and
`cleanupSucceeded: true`; the temporary user, database, bucket, tables and push
provider were deleted, the loopback backend stopped, and the ADB reverse mapping
removed. No `kilnplat_*` user was left behind.

## Harness defects found and fixed

The coordinator had only been syntax-checked before; these appeared on the first
real end-to-end runs.

1. **Batch launcher quoting.** `start()` built
   `cmd /d /s /c ""dart" "run" "tool/..." "..."`, which quotes the launcher name.
   `cmd` then resolves the literal name `dart` instead of `dart.bat` through
   `PATHEXT`, and the run stopped with `The system cannot find the path specified`
   and `dart failed (1)`. Only the arguments are quoted now:
   `cmd /d /s /c "dart "run" "tool/...""`.
2. **A stale app could report the next phase.** The Android loop switched
   `backend.phases.android` before force-stopping the previous app. The running
   app polled, saw the new phase, and reported `bootstrap_appwrite: Unknown phase`
   before the fresh build started, failing the run. The loop now force-stops
   first, clears that phase's reports, then sets the phase and starts the app. The
   web loop also clears its phase reports first.
3. **Mode switch reused the old kernel.** After rendering the services probe, the
   Gradle kernel task stayed up-to-date: the APK's `kernel_blob.bin` still
   contained the auth probe (`Unknown phase`) and the services run executed it.
   The generated depfile contains absolute paths with spaces. The runner now
   deletes `.dart_tool/flutter_build` and `build/app/intermediates/flutter` after
   rendering and before the Android build, so the new `main.dart` is compiled.
   The rebuilt kernel then contained `service checks` and the run passed.
4. **Cleanup treated an absent ADB listener as a failure.** `adb reverse
   --remove tcp:8767` exits non-zero when the mapping is already gone; that is a
   clean state, so it no longer marks the run as failed.

Operational note: a killed build can leave a zero-byte `app.dill`, after which the
next build hangs in `frontend_server`. Deleting `.dart_tool/flutter_build` clears
it; the runner now does this on every mode switch anyway.

## Evidence

- `.dart_tool/appwrite_platform_result.json` (auth) and
  `.dart_tool/appwrite_services_platform_result.json` (services): phase results,
  `cleanupSucceeded: true`, no error.
- `.dart_tool/appwrite_probe_ownership.json`: empty ownership after cleanup.
- Runner logs: `.dart_tool/platform_probe_run2.log` (auth),
  `.dart_tool/services_probe_run3.log` (services).

## Reproduction

```sh
export KILN_APPWRITE_ENDPOINT=https://appwrite.example.com/v1
export KILN_APPWRITE_PROJECT=<project id>
export KILN_APPWRITE_API_KEY=<server key, host only>
export KILN_ANDROID_DEVICE=emulator-5554

node tool/e2e/run_platform_probe.mjs              # auth, Android and web
node tool/e2e/run_platform_probe.mjs --services   # services, Android and web
```

Ports 8767 and 7357 must be free. Uninstall the previous fixture build before a
run. Do not run two probes concurrently.

## Still open

- iOS and macOS execution remains deferred as requested; existing platform code
  is not acceptance evidence.
- Google OAuth was accepted earlier in
  [Appwrite services and push](appwrite-services-push-2026-11-20.md); this run
  covers email/password auth plus the service contracts.
- Native push delivery needs the separate `--push` mode and the MQTT endpoint; it
  is not part of this auth/services run.
- A web page reload (as opposed to Flutter's hot restart) is still not automated.
