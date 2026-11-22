# K23 live adapter acceptance (Appwrite)

Date: 2026-11-22/23 (Asia/Jakarta). Target: the owner's self-hosted project
`6afebe9d000e9c351b3e` at `https://appwrite.tegardev.id/v1`, Appwrite 2.7.2.
No commit or deployment of Kiln itself was made.

## Result

The two adapters K23 called out as fake-only now pass against the live server
through their real implementations, not shared fakes:

```
00:00 +0: AppwriteFunctions invokes a deployed function through the adapter
00:01 +1: AppwriteFunctions forwards the JSON body to the function
00:01 +2: AppwriteFunctions reports a missing function as a typed Failure
00:02 +3: AppwriteFunctions rejects a non-HTTP method before sending
00:02 +4: AppwritePushTargets registers, upserts, updates and removes a target
00:02 +5: AppwritePushTargets rejects empty input with typed failures
00:03 +6: All tests passed!
```

What each proves:

| Check | Evidence |
| --- | --- |
| `AppwriteFunctions.invoke` returns the execution | deployed `node-22` function answered `200` with `{"ok":true,...}` |
| JSON body forwards | function echoed `"name":"Kiln"` and `"phase":"k23"` |
| Errors are typed | unknown function id → `Failure`, not a raw `AppwriteException` |
| Local validation | `TRACE` method rejected as `validation.invalid_input` before any request |
| `AppwritePushTargets.register` | created a real push target against a real FCM provider |
| Register is an upsert | second `register` returned the **same** target id with the rotated token |
| `update` / `unregister` | token replaced, then the target removed |
| Local validation | empty token / id → `Failure` |

## Temporary resources (all removed)

| Resource | Created | Deleted |
| --- | --- | --- |
| Function `kilnfn370676` (`node-22`, deployed + activated) | yes | `204` |
| FCM provider `kilnfcm70822` (from the owner's service account) | yes | `204` |
| Windows platform `kilnk2372889` (`dev.kiln.k23`, needed for the Origin header) | yes | `204` |
| Test user `kilnfnuser…` | yes | `204` |

Verified afterwards: no `kilnfn*` function, no `kilnfcm*` provider, no
`kilnfnuser*` user remains. The surviving `kilnclean_mwnx8bq3`,
`kilnroute_mwoxkctu` and `kilnplat_mwqebgjg` accounts predate this pass and are
listed in the earlier `.dart_tool/*ownership*.json` journals.

## Harness

`tool/e2e/k23_live_adapters_test.dart.tmpl`, rendered into the existing
`.dart_tool/appwrite_platform` fixture:

```bash
KILN_APPWRITE_ENDPOINT=... KILN_APPWRITE_PROJECT=... \
KILN_APPWRITE_TEST_EMAIL=... KILN_APPWRITE_TEST_PASSWORD=... \
KILN_APPWRITE_FUNCTION_ID=... KILN_APPWRITE_PUSH_PROVIDER=... \
flutter test test/k23_live_adapters_test.dart
```

Without those variables the group reports an explicit **skip** with the list of
variables, which is the K23 requirement: a skip must look like a skip, never
like a pass.

Three test-harness traps were found and solved; each one made a live suite in
`flutter test` look like a hang rather than an error:

1. `flutter_test` installs `_MockHttpOverrides`, which answers every request
   with an empty 400. A per-zone override is not enough because the Appwrite SDK
   builds its own `HttpClient()`; `HttpOverrides.global = null` is what reaches
   it.
2. The SDK initialises through `getApplicationDocumentsDirectory()` and
   `PackageInfo.fromPlatform()`. In a unit test those calls never complete, so
   the suite mocks `plugins.flutter.io/path_provider` and
   `dev.fluttercommunity.plus/package_info`.
3. The SDK sends an `Origin` header derived from the package name; the project
   rejected it until `dev.kiln.k23` was registered as a platform (removed after
   the run).

## Not covered

- `appwrite_push` (FCM) end-to-end delivery: needs an APK with package
  `dev.tegar.appwrite_demo` and a real FCM token, plus a device.
- `appwrite_push_native` (MQTT broker): covered separately by the earlier
  device push report.
- A deployed function is backend state, so this pass created one rather than
  assuming it exists; the suite still takes `KILN_APPWRITE_FUNCTION_ID`.

## Credentials

The API key, the Firebase service account and `google-services.json` lived only
in `.dart_tool/` (git-ignored) and were deleted at the end of the pass. The
template carries no key, DSN or service account. The API key was pasted into
chat, so it should be rotated by the owner.
