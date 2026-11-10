# Gate

`Gate` is the one-call facade over the registry. It reads a contract, invokes it,
and returns a `Result<T>` instead of throwing. The SDK sends success or failure
plus information; the application owns the UI.

```dart
final gate = Gate(registry);

final result = await gate.sendPasswordReset('user@example.com');
result.fold(
  ok: (_) => showSent(),
  err: (failure) => showError(failure),
);
```

## Reading services

| Member | Behavior |
| --- | --- |
| `gate.has<T>()` | True when the contract is registered |
| `gate.use<T>()` | Returns the contract, or throws `Failure(configuration.missing)` |
| `gate.<getter>` | Typed getter such as `gate.auth`, `gate.http`, `gate.storage` |
| `gate.call(action, {code, message, info})` | Runs an action and wraps it in `Result` |

`gate.call` catches `Failure` and any other error. A thrown `Failure` keeps its
code, kind, and details. An unexpected error becomes `FailureCode.unexpected`
unless `code`/`message` are supplied. Extra `info` is merged into
`Failure.details`, so the app can see the operation and context.

When a contract is missing, typed verbs return
`Err(configurationMissing)`. That is intentional: an optional extension being
absent is a normal outcome, not a crash. Use `gate.has<T>()` when the UI should
hide the action instead.

## Typed getters

`account`, `analytics`, `auth`, `calendar`, `network`, `crashReporter`,
`deepLinks`, `env`, `files`, `http`, `cache`, `localDb`, `location`, `logger`,
`mediaPicker`, `notifications`, `permissions`, `remoteDb`, `remoteConfig`,
`secureStorage`, `share`, `socialAuth`, `storage`, `flavor`, `session`,
`consent`, `clock`, `lifecycle`, `slots`, and `support`.

## Permissions

| Verb | Returns |
| --- | --- |
| `permissionStatus(kind)` | `Result<PermissionStatus>` |
| `requestPermission(kind, {requestIfDenied = true})` | `Result<PermissionStatus>` |

`requestPermission` delegates to `Permissions.ensure`; the app decides when to
ask and what to show for denied/permanently denied/unsupported.

## Auth and account

| Verb | Returns |
| --- | --- |
| `signIn(email:, password:)` | `Result<AuthSession>` |
| `signUp(email:, password:, displayName:)` | `Result<AuthSession>` |
| `signOut()` | `Result<void>` |
| `sendPasswordReset(email)` | `Result<void>` |
| `sendEmailVerification()` | `Result<void>` |
| `reloadUser()` | `Result<void>` |
| `updateDisplayName(displayName)` | `Result<void>` |
| `socialSignIn(provider)` | `Result<SocialCredential?>` |
| `socialSignOut()` | `Result<void>` |

`signOut` clears local credentials even when the backend cannot be reached; the
result represents local logout, not remote revocation.

## Remote database

| Verb | Returns |
| --- | --- |
| `remoteCreate(collection, data)` | `Result<Map<String, Object?>>` |
| `remoteRead(collection, id)` | `Result<Map<String, Object?>?>` |
| `remoteQuery(collection, {query})` | `Result<List<Map<String, Object?>>>` |
| `remoteUpdate(collection, id, data)` | `Result<Map<String, Object?>>` |
| `remoteDelete(collection, id)` | `Result<void>` |

The contract is `RemoteDatabase`; the provider is whichever connector is
installed. `remoteRead` returns `Ok(null)` for an absent record, while update and
delete produce `remote_database.not_found`.

## HTTP

| Verb | Returns |
| --- | --- |
| `httpSend(request)` | `Result<HttpResponse>` |
| `httpGet(uri, {headers, queryParameters, cancelToken})` | `Result<HttpResponse>` |
| `httpPost(uri, {body, headers, queryParameters, cancelToken})` | `Result<HttpResponse>` |
| `httpPut(...)` | `Result<HttpResponse>` |
| `httpPatch(...)` | `Result<HttpResponse>` |
| `httpDelete(...)` | `Result<HttpResponse>` |

HTTP status codes are not failures by themselves; the response is returned with
its status. Transport problems, timeouts, cancellation, and provider errors are
`Err`.

## Cache and files

| Verb | Returns |
| --- | --- |
| `invalidateCache(prefix, {tag})` | `Result<void>` |
| `clearCache()` | `Result<void>` |
| `uploadFile(file, {onProgress})` | `Result<StoredFile>` |
| `downloadFile(path, {onProgress})` | `Result<List<int>>` |

The cache is optional and only available when `http_cache` is installed. File
storage is provided by `storage`, `supabase`, `appwrite`, `firebase`, or `neon`.

## Local database

| Verb | Returns |
| --- | --- |
| `localGet(collection, key)` | `Result<Map<String, Object?>?>` |
| `localPut(collection, key, data)` | `Result<void>` |

For queries and streams, read `LocalDatabase` directly through the gate:
`gate.localDb.query(...)`.

## Analytics, config, and reporting

| Verb | Returns |
| --- | --- |
| `captureEvent(event, {properties})` | `Result<void>` |
| `identifyUser(userId, {traits})` | `Result<void>` |
| `resetAnalytics()` | `Result<void>` |
| `fetchRemoteConfig()` | `Result<void>` |
| `addCalendarEvent(event)` | `Result<bool>` |
| `reportError(error, {stackTrace, context})` | `Result<void>` |
| `reportMessage(message, {context})` | `Result<void>` |

Analytics and crash reporting are consent-gated by their extensions. Calling the
Gate does not bypass `ConsentController` or PII scrubbing.

## Media and notifications

| Verb | Returns |
| --- | --- |
| `pickImage({source, maxWidth, maxHeight, imageQuality})` | `Result<PickedImage?>` |
| `requestNotificationPermission()` | `Result<bool>` |
| `showNotification(message)` | `Result<void>` |
| `scheduleNotification(message, when)` | `Result<void>` |
| `cancelNotification(id)` | `Result<void>` |
| `cancelAllNotifications()` | `Result<void>` |

A null image or false notification permission is an `Ok`, not an `Err`. A
cancelled picker is also represented by `null`/`Ok` according to the contract;
provider-specific cancellation failures are mapped to their stable codes.

## Secure storage and preferences

| Verb | Returns |
| --- | --- |
| `readSecure(key)` | `Result<String?>` |
| `writeSecure(key, value)` | `Result<void>` |
| `deleteSecure(key)` | `Result<void>` |
| `readAllSecure()` | `Result<Map<String, String>>` |
| `clearSecure()` | `Result<void>` |
| `readValue(key)` | `Result<String?>` |
| `writeValue(key, value)` | `Result<void>` |
| `deleteValue(key)` | `Result<void>` |
| `hasValue(key)` | `Result<bool>` |
| `storageKeys()` | `Result<Set<String>>` |
| `clearValues()` | `Result<void>` |

`SecureStorage` is for tokens and secrets; `Storage` is for preferences and flags.

## Share and location

| Verb | Returns |
| --- | --- |
| `shareContent(content, {origin})` | `Result<ShareOutcome>` |
| `currentLocation({accuracy})` | `Result<GeoPosition>` |
| `locationServiceEnabled()` | `Result<bool>` |

## Extension-specific gates

Some extensions ship a typed facade next to their module, because their verbs
are not part of `kiln_core`. Import the gate file once where it is used:

```dart
import 'package:my_app/extensions/theme/gate_theme.dart';
import 'package:my_app/extensions/l10n/gate_l10n.dart';
import 'package:my_app/extensions/biometric/gate_biometric.dart';

await gate.setThemeMode(ThemeMode.dark);
await gate.setLocale(const Locale('id'));
final unlocked = await gate.biometricUnlock();
```

| Extension | Gate file | Adds |
| --- | --- | --- |
| `biometric` | `gate_biometric.dart` | availability, authenticate, unlock, app-lock getters |
| `connectivity` | `gate_connectivity.dart` | `networkReachable()`, device monitor getter |
| `crash_report` | `gate_crash_report.dart` | breadcrumbs, report user/context, consent flag |
| `deep_link` | `gate_deep_link.dart` | custom and universal link builders |
| `env` | `gate_env.dart` | typed URI/duration/bool reads, validation, schema |
| `l10n` | `gate_l10n.dart` | locale getter, `setLocale`, follow system |
| `logger` | `gate_logger.dart` | log level, records, clear |
| `permission` | `gate_permission.dart` | batch `ensurePermissions`, open settings |
| `remote_config` | `gate_remote_config.dart` | feature/typed reads, defaults, changes |
| `social_login` | `gate_social_login.dart` | social sign-in/out |
| `theme` | `gate_theme.dart` | theme mode and controller |

These are generated by the extension brick, not by `kiln_core`. They still
follow the same `Result` rule. The extension page in this site lists the exact
members for each installed extension.

## Example: one call, one result

```dart
Future<void> openCamera() async {
  final permission = await gate.requestPermission(PermissionKind.camera);
  if (permission.failureOrNull != null) {
    return showFailure(permission.failureOrNull!);
  }
  final image = await gate.pickImage(source: MediaSource.camera);
  image.fold(
    ok: (picked) => picked == null ? null : showPreview(picked),
    err: (failure) => showFailure(failure),
  );
}
```

The app decides what a denied permission, a cancelled picker, or a missing
extension looks like. The SDK only returns state and information.
