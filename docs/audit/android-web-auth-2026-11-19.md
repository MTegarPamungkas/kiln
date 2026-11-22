# Android and web auth functional verification

Date: 2026-11-19. UI was intentionally minimal. No commit or deployment was made.

## Result

All six phases passed: **52 assertions**, 26 on Android and 26 on web.

| Target | Login | Restore and logout | Restart after logout | Restart mechanism |
| --- | ---: | ---: | ---: | --- |
| Android emulator, API 37 | 12 | 11 | 3 | Full process force-stop and launch |
| Chrome 157 | 12 | 11 | 3 | Flutter web hot restart, fresh application/client state |

The auth adapter and router came from the current extension templates. The
fixture used actual SharedPreferences/browser storage, not mock persistence.
Appwrite client version resolved to 28.4.0. Web hot restart retains the browser
profile and cookies; a browser page reload/close-and-reopen was not automated.

Checks covered hidden protected content during restoration, signed-out initial
state, invalid password, login/session-controller updates, return URL/query
preservation, persistence, JWT creation and logout. Logout also invalidated the
server session: the memory backend rejected its previously accepted JWT.

The Node backend used an in-memory Map and validated each bearer JWT against
the actual Appwrite Account API. Dio exercised anonymous rejection, create,
read, update, delete and missing-item responses. **This is not an Appwrite
database/storage contract result.** No database or bucket was created.

## Defects found and corrected

1. Credential reset called every setter even if the credential never existed.
   Appwrite's setters add HTTP headers even for empty values. Following a 401,
   the resulting Authorization header caused the browser preflight to fail
   against the server's allowed-header list. Reset now clears only credentials
   present in SDK config or headers. A regression protects absent credentials;
   the actual Chrome login/retry flow passed after this change.
2. A raw Flutter fixture lacked Android desugaring and failed AAR validation
   because of Appwrite's transitive notification plugin. Kiln create already
   applied desugaring globally; installation into existing apps also needs it.
   Native manifest setup now supports core_library_desugaring. Appwrite declares
   it with min_sdk 24, and notifications declares it too. The fixture applies
   the same native patches and then built/ran successfully.

The upstream [Flutter SDK setup guide](https://pub.dev/documentation/appwrite/latest/)
documents the Android plugin requirements and platform identifiers. The run
created an exact Android registration for the probe package; the existing web
registration was reused unchanged.

Local regression checks also passed: 183 kiln_extension_sdk tests, 160 kiln_cli
tests, rendered Appwrite analysis/tests, root analysis, metadata/golden/docs
checks and regenerated bundle/registry consistency. Opt-in provider tests in the
rendered suite remain skipped; the 52 platform assertions above are recorded
separately. The ignored local CLI executable was rebuilt.

## Isolation and cleanup

One temporary user and one temporary Android platform registration were
created in the owner-authorized project. Both were deleted after the tests.
No existing users, platforms, databases or buckets were modified. The loopback
backend was stopped and its ADB reverse mapping removed. Server API keys were
kept in host memory and never sent to Flutter or written to the fixture.

The credential-free local report is
`.dart_tool/appwrite_platform_result.json`; transient debugging attempts are not
counted as passing phases. The report records the final phase results and
successful cleanup.

## Reproduction

Set KILN_APPWRITE_ENDPOINT, KILN_APPWRITE_PROJECT and KILN_APPWRITE_API_KEY in
the coordinator's process environment, then run:

```sh
node tool/e2e/run_platform_probe.mjs
node tool/e2e/run_platform_probe.mjs --android
node tool/e2e/run_platform_probe.mjs --web
```

The runner renders current templates, builds a temporary app, provisions only
owned temporary resources, and writes a sanitized report in finally. Supply
KILN_ANDROID_DEVICE to select another emulator. The server key needs user and
platform provisioning/deletion scopes. Web needs a pre-existing registration
that allows localhost; the runner does not broaden it. Ports 8767 and 7357
must be free. Do not run two probes concurrently.

The recorded run was coordinated through the test tools using these same
render/backend/phase steps. The new standalone coordinator was syntax-checked;
an additional complete run through that wrapper has not been counted here.

The fixture and coordinator run locally under `.dart_tool/`. The backend is a
development-only test control service and must not be exposed or deployed.

## Still unverified

OAuth provider configuration and redirects, Appwrite database/storage/realtime,
push delivery, recovery/verification email, iOS/macOS and a full browser page
reload remain separate acceptance work. The Computer Use tool stopped Chrome
UI inspection because it could not confidently determine the window URL;
verification continued through application reports and host-side test code,
without bypassing that UI restriction.
