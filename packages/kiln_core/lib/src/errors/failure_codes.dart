/// Stable, machine-readable failure codes shared by every Kiln contract.
///
/// The string value is part of the public API: it appears in logs, analytics,
/// crash reports, and user-facing failure messages. Never rename a value that
/// has shipped. Add a new constant instead.
final class FailureCode {
  const FailureCode(this.value);

  final String value;

  static const networkTimeout = FailureCode('network.timeout');
  static const networkOffline = FailureCode('network.offline');
  static const networkUnreachable = FailureCode('network.unreachable');
  static const networkServer = FailureCode('network.server');
  static const networkRetryExhausted = FailureCode('network.retry_exhausted');
  static const networkUnknown = FailureCode('network.unknown');

  static const authInvalidCredentials = FailureCode('auth.invalid_credentials');
  static const authSessionExpired = FailureCode('auth.session_expired');
  static const authEmailNotVerified = FailureCode('auth.email_not_verified');
  static const authUnauthorized = FailureCode('auth.unauthorized');
  static const authCancelled = FailureCode('auth.cancelled');
  static const authProviderDisabled = FailureCode('auth.provider_disabled');

  static const permissionDenied = FailureCode('permission.denied');
  static const permissionPermanentlyDenied = FailureCode(
    'permission.permanently_denied',
  );
  static const permissionRestricted = FailureCode('permission.restricted');

  static const validationInvalidInput = FailureCode('validation.invalid_input');
  static const validationUnsupportedValue = FailureCode(
    'validation.unsupported_value',
  );

  static const configurationMissing = FailureCode('configuration.missing');
  static const configurationInvalid = FailureCode('configuration.invalid');

  static const storageReadFailed = FailureCode('storage.read_failed');
  static const storageWriteFailed = FailureCode('storage.write_failed');
  static const storageNotFound = FailureCode('storage.not_found');

  static const secureStorageUnavailable = FailureCode(
    'secure_storage.unavailable',
  );
  static const secureStorageReadFailed = FailureCode(
    'secure_storage.read_failed',
  );
  static const secureStorageWriteFailed = FailureCode(
    'secure_storage.write_failed',
  );

  static const databaseNotFound = FailureCode('database.not_found');
  static const databaseConflict = FailureCode('database.conflict');
  static const databaseUnavailable = FailureCode('database.unavailable');
  static const databaseQueryFailed = FailureCode('database.query_failed');

  static const remoteDatabaseNotFound = FailureCode(
    'remote_database.not_found',
  );
  static const remoteDatabaseConflict = FailureCode('remote_database.conflict');
  static const remoteDatabaseUnavailable = FailureCode(
    'remote_database.unavailable',
  );
  static const remoteDatabaseQueryFailed = FailureCode(
    'remote_database.query_failed',
  );

  static const fileNotFound = FailureCode('file.not_found');
  static const fileUploadFailed = FailureCode('file.upload_failed');
  static const fileDownloadFailed = FailureCode('file.download_failed');
  static const fileDeleteFailed = FailureCode('file.delete_failed');

  static const functionsNotFound = FailureCode('functions.not_found');
  static const functionsUnavailable = FailureCode('functions.unavailable');

  static const notificationsPermissionDenied = FailureCode(
    'notifications.permission_denied',
  );
  static const notificationsUnavailable = FailureCode(
    'notifications.unavailable',
  );

  static const deepLinkInvalid = FailureCode('deep_link.invalid');
  static const deepLinkUnavailable = FailureCode('deep_link.unavailable');

  static const mediaCancelled = FailureCode('media.cancelled');
  static const mediaPermissionDenied = FailureCode('media.permission_denied');
  static const mediaUnavailable = FailureCode('media.unavailable');
  static const mediaInvalid = FailureCode('media.invalid');

  static const cacheUnavailable = FailureCode('cache.unavailable');
  static const cacheInvalidEntry = FailureCode('cache.invalid_entry');

  static const sessionExpired = FailureCode('session.expired');

  static const cancelled = FailureCode('cancelled');
  static const unavailable = FailureCode('unavailable');
  static const unsupportedPlatform = FailureCode(
    'support.unsupported_platform',
  );
  static const unsupportedDevice = FailureCode('support.unsupported_device');
  static const unexpected = FailureCode('unexpected');

  /// Every code that ships with `kiln_core`.
  static const List<FailureCode> known = [
    networkTimeout,
    networkOffline,
    networkUnreachable,
    networkServer,
    networkRetryExhausted,
    networkUnknown,
    authInvalidCredentials,
    authSessionExpired,
    authEmailNotVerified,
    authUnauthorized,
    authCancelled,
    authProviderDisabled,
    permissionDenied,
    permissionPermanentlyDenied,
    permissionRestricted,
    validationInvalidInput,
    validationUnsupportedValue,
    configurationMissing,
    configurationInvalid,
    storageReadFailed,
    storageWriteFailed,
    storageNotFound,
    secureStorageUnavailable,
    secureStorageReadFailed,
    secureStorageWriteFailed,
    databaseNotFound,
    databaseConflict,
    databaseUnavailable,
    databaseQueryFailed,
    remoteDatabaseNotFound,
    remoteDatabaseConflict,
    remoteDatabaseUnavailable,
    remoteDatabaseQueryFailed,
    fileNotFound,
    fileUploadFailed,
    fileDownloadFailed,
    fileDeleteFailed,
    notificationsPermissionDenied,
    notificationsUnavailable,
    deepLinkInvalid,
    deepLinkUnavailable,
    mediaCancelled,
    mediaPermissionDenied,
    mediaUnavailable,
    mediaInvalid,
    cacheUnavailable,
    cacheInvalidEntry,
    sessionExpired,
    cancelled,
    unavailable,
    unsupportedPlatform,
    unsupportedDevice,
    unexpected,
  ];

  @override
  bool operator ==(Object other) =>
      other is FailureCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
