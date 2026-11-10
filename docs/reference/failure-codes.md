# Failure codes

Contracts fail by throwing `Failure`. The Gate turns it into `Err`; feature code
can also use `Result` directly. A failure carries a stable code, a human message,
a broad kind, an optional cause/stack trace, details, and a retryable flag.

```dart
final result = await gate.httpGet(uri);
result.fold(
  ok: (response) => render(response),
  err: (failure) {
    log(failure.code.value, failure.message, failure.details);
    if (failure.isRetryable) scheduleRetry();
  },
);
```

## Failure shape

```dart
const Failure({
  required FailureCode code,
  required String message,
  FailureKind kind = FailureKind.unknown,
  Object? cause,
  StackTrace? stackTrace,
  Map<String, Object?> details = const {},
  bool isRetryable = false,
});
```

`FailureCode.value` is public API. Never rename a shipped string; add a new code
instead. `Failure` equality compares code, message, kind, and `isRetryable`.
`isAuthFailure`, `isPermissionFailure`, and `isCancelled` are convenience
predicates.

## Kinds

`FailureKind`: `network`, `authentication`, `authorization`, `permission`,
`validation`, `configuration`, `storage`, `database`, `file`, `notification`,
`deepLink`, `media`, `cache`, `session`, `cancelled`, `unavailable`,
`unsupported`, `unknown`.

A kind routes presentation and fallback behavior; the code is the precise
machine-readable reason.

## Network

| Constant | Code | Meaning |
| --- | --- | --- |
| `networkTimeout` | `network.timeout` | Request exceeded its timeout |
| `networkOffline` | `network.offline` | No usable connection |
| `networkUnreachable` | `network.unreachable` | Host or route unavailable |
| `networkServer` | `network.server` | Server-side 5xx or protocol failure |
| `networkRetryExhausted` | `network.retry_exhausted` | Retry budget/attempts exhausted |
| `networkUnknown` | `network.unknown` | Unclassified network failure |

Transient network failures are the usual candidates for `isRetryable: true`.
Do not retry a request merely because it is a network failure; respect method
idempotency and the retry extension policy.

## Auth

| Constant | Code | Meaning |
| --- | --- | --- |
| `authInvalidCredentials` | `auth.invalid_credentials` | Wrong email/password |
| `authSessionExpired` | `auth.session_expired` | Session or refresh token expired |
| `authEmailNotVerified` | `auth.email_not_verified` | Account needs verification |
| `authUnauthorized` | `auth.unauthorized` | Missing/invalid credential for the operation |
| `authCancelled` | `auth.cancelled` | User cancelled a social/OAuth flow |
| `authProviderDisabled` | `auth.provider_disabled` | Provider is not enabled for the project |

A failed login must not clear an existing valid session unless the provider
explicitly says the session is invalid. `signOut` always clears local state.

## Permission

| Constant | Code | Meaning |
| --- | --- | --- |
| `permissionDenied` | `permission.denied` | User denied the request |
| `permissionPermanentlyDenied` | `permission.permanently_denied` | Denied until settings change |
| `permissionRestricted` | `permission.restricted` | Platform policy restricts the capability |

Permission state is data: `PermissionStatus.unsupported` is also available
without throwing. The app chooses whether to open settings or show an
explanation.

## Validation and configuration

| Constant | Code | Meaning |
| --- | --- | --- |
| `validationInvalidInput` | `validation.invalid_input` | Malformed or out-of-range input |
| `validationUnsupportedValue` | `validation.unsupported_value` | Valid type, unsupported value |
| `configurationMissing` | `configuration.missing` | Required key, endpoint, or credential absent |
| `configurationInvalid` | `configuration.invalid` | Configuration present but malformed |

A missing extension through `Gate` also produces `configuration.missing` with
the contract name in `details`.

## Local storage

| Constant | Code | Meaning |
| --- | --- | --- |
| `storageReadFailed` | `storage.read_failed` | Preference read failed |
| `storageWriteFailed` | `storage.write_failed` | Preference write failed |
| `storageNotFound` | `storage.not_found` | Requested local value is absent |
| `secureStorageUnavailable` | `secure_storage.unavailable` | Keychain/Keystore/WebCrypto unavailable |
| `secureStorageReadFailed` | `secure_storage.read_failed` | Secure read failed |
| `secureStorageWriteFailed` | `secure_storage.write_failed` | Secure write failed |

## Local database

| Constant | Code | Meaning |
| --- | --- | --- |
| `databaseNotFound` | `database.not_found` | Local record absent |
| `databaseConflict` | `database.conflict` | Unique/version conflict |
| `databaseUnavailable` | `database.unavailable` | Database cannot be opened/used |
| `databaseQueryFailed` | `database.query_failed` | Query or mutation failed |

## Remote database

| Constant | Code | Meaning |
| --- | --- | --- |
| `remoteDatabaseNotFound` | `remote_database.not_found` | Remote row absent |
| `remoteDatabaseConflict` | `remote_database.conflict` | Unique/version conflict |
| `remoteDatabaseUnavailable` | `remote_database.unavailable` | Backend unreachable or unavailable |
| `remoteDatabaseQueryFailed` | `remote_database.query_failed` | Query rejected or failed |

`read` returns `null` for an absent row; `update`/`delete` throw
`remote_database.not_found`. See
[contract behavior](../concepts/contract-behavior.md).

## Files

| Constant | Code | Meaning |
| --- | --- | --- |
| `fileNotFound` | `file.not_found` | Object absent |
| `fileUploadFailed` | `file.upload_failed` | Upload failed |
| `fileDownloadFailed` | `file.download_failed` | Download failed |
| `fileDeleteFailed` | `file.delete_failed` | Delete failed |

## Notifications, deep links, and media

| Constant | Code | Meaning |
| --- | --- | --- |
| `notificationsPermissionDenied` | `notifications.permission_denied` | Notification permission denied |
| `notificationsUnavailable` | `notifications.unavailable` | Plugin/service unavailable |
| `deepLinkInvalid` | `deep_link.invalid` | Link cannot be parsed or routed |
| `deepLinkUnavailable` | `deep_link.unavailable` | Link service unavailable |
| `mediaCancelled` | `media.cancelled` | Picker cancelled |
| `mediaPermissionDenied` | `media.permission_denied` | Camera/gallery permission denied |
| `mediaUnavailable` | `media.unavailable` | Picker unavailable |
| `mediaInvalid` | `media.invalid` | Picker returned invalid data |

## Cache, session, and generic

| Constant | Code | Meaning |
| --- | --- | --- |
| `cacheUnavailable` | `cache.unavailable` | Cache backend unavailable |
| `cacheInvalidEntry` | `cache.invalid_entry` | Stored entry is corrupt/incompatible |
| `sessionExpired` | `session.expired` | Application session deadline passed |
| `cancelled` | `cancelled` | Operation was cancelled cooperatively |
| `unavailable` | `unavailable` | General service unavailability |
| `unexpected` | `unexpected` | Unclassified/unexpected error |

## Support

| Constant | Code | Meaning |
| --- | --- | --- |
| `unsupportedPlatform` | `support.unsupported_platform` | No implementation for this platform |
| `unsupportedDevice` | `support.unsupported_device` | Platform exists, device capability absent |

`SupportInfo.toFailure()` maps `notConfigured` to `configuration.missing`,
`permissionDenied` to `permission.denied`, and `unavailable` to `unavailable`.

## Retry and cancellation

- `isRetryable` is provider-set, not inferred from the kind. Network/5xx/timeout
  failures are typical; validation, auth-after-refresh, and cancellation are not.
- Check `failure.isCancelled` before showing an error dialog.
- A cancelled `HttpRequest` must not be retried by generic middleware.
- The `http_retry` extension retries only idempotent requests and respects a
  retry budget and `Retry-After`.

## Stability

`FailureCode.known` lists every code that ships with `kiln_core`. Add new codes
there, add a friendly message to localization, and keep the old string value.
