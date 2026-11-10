# Contracts

Every application feature talks to `kiln_core` contracts. An extension provides
the implementation, and the application reads it from the registry or through
the Gate. This page is the map of the public contracts; behavior shared by every
provider is specified in [contract behavior](../concepts/contract-behavior.md).

## Reading a contract

```dart
final storage = RegistryScope.read<Storage>(context);
final token = await storage.read('access_token');
```

Or through the single-result gate:

```dart
final result = await gate.readValue('access_token');
result.fold(
  ok: (value) => print(value),
  err: (failure) => print(failure.code),
);
```

A contract is a capability, not a package name. `RemoteDatabase` can be backed
by Appwrite, Supabase, Firebase, or Neon; `HttpClient` can be Dio or a test fake.
Feature code never imports the provider.

## Contract map

| Group | Contracts |
| --- | --- |
| Auth and account | `AuthRepository`, `AccountManagement`, `SocialAuth`, `SocialLogin` |
| Data and storage | `Storage`, `SecureStorage`, `LocalDatabase`, `RemoteDatabase`, `FileStorage` |
| Network | `HttpClient`, `HttpPipeline`, `HttpCache` |
| Device and platform | `NetworkMonitor`, `Permissions`, `Notifications`, `DeepLinks`, `MediaPicker`, `ShareService`, `CalendarService`, `LocationProvider` |
| Observability and config | `AppLogger`, `Analytics`, `CrashReporter`, `RemoteConfig`, `Env`, `AppFlavor` |

Cross-cutting values live in the same package: `AuthSession`, `Failure`,
`FailureCode`, `Result`, `SupportInfo`, `RemoteQuery`, `LocalQuery`, and the
device value objects.

## Auth and account

### `AuthRepository`

| Member | Result |
| --- | --- |
| `currentSession` | Current `AuthSession?` |
| `authStateChanges` | Broadcast `Stream<AuthSession?>` |
| `signIn(email, password)` | `Future<AuthSession>` |
| `signUp(email, password, displayName?)` | `Future<AuthSession>` |
| `signOut()` | `Future<void>`; clears local state even when revocation fails |

`AuthSession` carries `userId`, optional `expiresAt`, `email`, `displayName`, and
a metadata map. Check expiry with `session.isExpired(clock, leeway: ...)`; the
app template also installs a `SessionExpiryGuard`.

### `AccountManagement`

`AccountManagement` composes three optional capabilities:

| Interface | Members |
| --- | --- |
| `PasswordRecovery` | `sendPasswordResetEmail(email)` |
| `EmailVerification` | `isEmailVerified`, `sendEmailVerification()`, `reloadUser()` |
| `ProfileUpdate` | `updateDisplayName(name)`, `updatePhotoUrl(url?)` |

Providers throw `Failure` when an endpoint is not configured. The Gate exposes
the common calls as `sendPasswordReset`, `sendEmailVerification`, `reloadUser`,
and `updateDisplayName`.

### `SocialAuth` and `SocialLogin`

```dart
final credential = await gate.socialSignIn(SocialProvider.google);
if (credential != null) {
  // credential.idToken, accessToken, email, displayName
}
```

`SocialProvider` is `google` or `apple`. A null result means the user cancelled.
`SocialLogin` is the higher-level service supplied by `social_login`; both
implement the same contract, and `signOut()` clears provider state.

## Data and storage

### `Storage` and `SecureStorage`

| Contract | Members |
| --- | --- |
| `Storage` | `read`, `write`, `delete`, `containsKey`, `keys`, `clear` |
| `SecureStorage` | `read`, `write`, `delete`, `readAll`, `clear` |

`Storage` is for non-sensitive preferences. `SecureStorage` is backed by
Keychain/Keystore/WebCrypto and is the right place for tokens. Storage values are
strings; encode structured data at the boundary.

### `LocalDatabase`

| Member | Result |
| --- | --- |
| `put(collection, key, data)` | Upsert one document |
| `get(collection, key)` | `Map?`, null when absent |
| `query(collection, {LocalQuery})` | `List<LocalRecord>` |
| `delete(collection, key)` | Remove one document |
| `watch(collection, {LocalQuery})` | Stream of matching records |
| `close()` | Release the database |

`LocalQuery` supports `where`, `orderBy`, `descending`, `limit`, and `offset`.
The Gate currently exposes `localGet` and `localPut`; use the contract for
queries and streams.

### `RemoteDatabase`

| Member | Result |
| --- | --- |
| `create(collection, data)` | Created row, including its id |
| `read(collection, id)` | Row or `null` |
| `query(collection, {RemoteQuery})` | List of rows |
| `update(collection, id, data)` | Updated row |
| `delete(collection, id)` | `void` |
| `watch(collection, id)` | Snapshot + changes; `null` when absent/deleted |

`RemoteQuery` supports `filters`, `orderBy`, `limit`, `offset`, and an opaque
`cursor`. Every filter is ANDed; repeated filters on one field are preserved.
`RemoteFilterOperator` includes equality, comparison, `inList`, `notInList`,
`arrayContains`, `isNull`, and `isNotNull`.

Optional interfaces:

- `PaginatedRemoteDatabase.queryPage` returns `RemotePage` with `nextOffset`,
  `nextCursor`, and `totalCount`. No bundled connector currently advertises it;
  `query` with limit/offset is the portable path.
- `BatchRemoteDatabase.writeBatch` applies `RemoteWrite` insert/update/delete
  operations together. `createMany`, `updateMany`, and `deleteMany` are
  convenience helpers.

See [contract behavior: pagination and filters](../concepts/contract-behavior.md)
for exact semantics.

### `FileStorage`

| Member | Result |
| --- | --- |
| `upload(FileUpload)` | `StoredFile` |
| `download(path)` | `List<int>` |
| `url(path, {expiresIn})` | Signed/download `Uri` |
| `delete(path)` | `void` |

`FileUpload` contains `path`, `bytes`, optional `contentType`, and metadata.
`ProgressCallback` reports `0..1`. A missing object on download is
`file.not_found`; deleting an absent object is provider-defined.

## Network

### `HttpClient`

```dart
final client = registry.read<HttpClient>();
final response = await client.get(Uri.parse('/users'));
```

Methods: `send`, `get`, `post`, `put`, `patch`, `delete`. Each accepts headers,
optional query parameters, and a `HttpCancelToken`. `HttpRequest` is
backend-neutral; `HttpResponse` exposes `statusCode`, `data`, `headers`,
`requestUri`, `duration`, `fromCache`, and case-insensitive `header(name)`.

Relative URIs are resolved by the provider (Dio uses `baseUrl`). Cancellation
throws `Failure(cancelled)`; timeouts become `network.timeout`.

### `HttpPipeline` and `HttpMiddleware`

`HttpPipeline.execute(request, terminal)` wraps ordered middleware around a
transport. Lower priority runs first; equal priorities keep insertion order.
Common middleware includes auth, retry, cache, and logging.

```dart
pipeline.use(const MyMiddleware(), priority: 20);
```

A middleware may replace the request, short-circuit the response, or throw a
`Failure`. It must not render UI.

### `HttpCache`

`read(key)` returns a `CacheEntry?`; `write` stores a response with optional TTL
and tags; `invalidate(prefix, {tag})` removes matching entries; `clear` removes
everything. The bundled `http_cache` extension implements policy, `Vary`,
ETag/304, stale windows, and authenticated-request bypass.

## Device and platform

### `NetworkMonitor`

`status` is `unknown`, `online`, or `offline`; `changes` streams transitions;
`dispose` cancels the platform subscription. `connectivity` provides the
implementation and an optional offline guard middleware.

### `Permissions`

`PermissionKind`: camera, microphone, photos, notifications, location,
locationAlways, contacts, calendar, bluetooth, storage.

`PermissionStatus`: granted, limited, denied, permanentlyDenied, restricted,
unsupported. `ensure(kind, {requestIfDenied})` is the normal one-shot call;
`openSettings()` sends the user to system settings.

### `Notifications`

`show`, `schedule`, `cancel`, `cancelAll`, and `requestPermission` manage local
notifications. `taps` streams `NotificationTap(payload)`. Call `initialize()` and
`dispose()` through the provider lifecycle. `NotificationMessage` carries id,
title, body, optional payload, and channel id.

### `DeepLinks`

`initialLink` is the cold-start URI; `links` streams later links; `dispose`
cancels listeners. Invalid links fail with `deep_link.invalid`.

### `MediaPicker`

`pickImage(source, maxWidth, maxHeight, imageQuality)` returns `PickedImage?`.
A null result means cancellation; `PickedImage` carries path, name, optional
bytes, MIME type, dimensions, and size.

### `ShareService`

`share(ShareContent, {origin})` returns `shared`, `dismissed`, or `unavailable`.
`ShareContent` supports text, subject, and files. `origin` anchors the iPad
popover.

### `CalendarService`

`addEvent(CalendarEvent)` returns false when the native calendar UI is
unavailable. `CalendarEvent` has title, start/end, description, location, and
`allDay`.

### `LocationProvider`

`current({accuracy})` requests permission when necessary and returns a
`GeoPosition`; `updates(...)` streams positions; `isServiceEnabled()` checks the
platform service without prompting. `LocationAccuracy` ranges from `lowest` to
`best`. `GeoPosition` contains latitude, longitude, timestamp, accuracy,
altitude, heading, and speed.

## Observability and config

### `AppLogger`

`log(level, message, {error, stackTrace, data})` plus `trace`, `debug`, `info`,
`warning`, and `error` helpers. `LogLevel` is trace/debug/info/warning/error.
The logger extension adds sinks, redaction, memory/file output, and an HTTP log
middleware.

### `Analytics`

`capture(event, properties)`, `identify(userId, traits)`, and `reset()`. The
analytics extension places consent and PII scrubbing in front of the provider;
do not bypass the contract with a direct SDK call.

### `CrashReporter`

`captureError`, `captureMessage`, `addBreadcrumb`, `setUser`, and `setContext`.
The app template forwards Flutter and platform errors to the logger, then to the
crash reporter when installed.

### `RemoteConfig`

`fetch` loads a pending snapshot; `activate` promotes it; `fetchAndActivate` does
both. Typed getters `getBool`, `getInt`, `getDouble`, `getString`, and `getJson`
read synchronously with caller defaults. `changes` emits after activation.
`setDefaults` supplies fallbacks.

### `Env`

`read(key)`, `containsKey(key)`, and `values` expose compile-time
`--dart-define` configuration. The env extension adds validation, typed
accessors, and debug redaction. Secrets belong in build-time defines or a backend,
not in source.

### `AppFlavor`

`AppFlavor` is a value object with `name` and `isProduction`; standard values are
`development`, `staging`, and `production`. Custom flavors are allowed. Use
`when(...)` for exhaustive branching. The flavors extension installs the current
flavor into the registry.

## Related reference

- [Gate](gate.md) — every typed verb and result contract.
- [Failure codes](failure-codes.md) — stable codes and error handling.
- [Core runtime](core-runtime.md) — bootstrap, registry, lifecycle, support, slots,
  session, consent, and utilities.
- [Contract behavior](../concepts/contract-behavior.md) — missing records,
  pagination, filters, logout, unsupported backends.
