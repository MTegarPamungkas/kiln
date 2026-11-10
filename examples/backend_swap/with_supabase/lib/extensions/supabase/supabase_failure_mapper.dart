import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts Supabase errors into a uniform [Failure].
///
/// [fallbackCode] and [fallbackKind] are used for unrecognized errors so the
/// caller can signal which operation failed (upload, download, database write,
/// and so on).
Failure mapSupabaseError(
  Object error, {
  StackTrace? stackTrace,
  FailureCode fallbackCode = FailureCode.unexpected,
  FailureKind fallbackKind = FailureKind.unknown,
}) {
  if (error is Failure) {
    return error;
  }
  if (error is AuthException) {
    return _mapAuthException(error, stackTrace);
  }
  if (error is PostgrestException) {
    return _mapPostgrestException(error, stackTrace);
  }
  if (error is StorageException) {
    return _mapStorageException(error, stackTrace, fallbackCode);
  }
  if (error is TimeoutException) {
    return Failure(
      code: FailureCode.networkTimeout,
      message: 'The request to Supabase timed out.',
      kind: FailureKind.network,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }
  final network = _networkFailure(error, stackTrace);
  if (network != null) {
    return network;
  }
  return Failure(
    code: fallbackCode,
    message: error.toString(),
    kind: fallbackKind,
    cause: error,
    stackTrace: stackTrace,
  );
}

Failure _mapAuthException(AuthException error, StackTrace? stackTrace) {
  final code = (error.code ?? '').toLowerCase();
  final message = error.message.toLowerCase();
  Failure build(
    FailureCode failureCode,
    FailureKind kind, {
    bool retryable = false,
  }) {
    return Failure(
      code: failureCode,
      message: error.message,
      kind: kind,
      cause: error,
      stackTrace: stackTrace,
      details: <String, Object?>{
        if (error.code != null) 'supabase_code': error.code,
        if (error.statusCode != null) 'status_code': error.statusCode,
      },
      isRetryable: retryable,
    );
  }

  if (code.contains('invalid_credentials') ||
      code.contains('invalid_grant') ||
      message.contains('invalid login credentials')) {
    return build(
      FailureCode.authInvalidCredentials,
      FailureKind.authentication,
    );
  }
  if (code.contains('email_not_confirmed') ||
      message.contains('email not confirmed')) {
    return build(FailureCode.authEmailNotVerified, FailureKind.authentication);
  }
  if (code.contains('user_not_found')) {
    return build(
      FailureCode.authInvalidCredentials,
      FailureKind.authentication,
    );
  }
  if (code.contains('provider_disabled') ||
      code.contains('signup_disabled') ||
      message.contains('provider is not enabled')) {
    return build(FailureCode.authProviderDisabled, FailureKind.authorization);
  }
  if (code.contains('session_not_found') ||
      code.contains('session_expired') ||
      code.contains('refresh_token_not_found') ||
      code.contains('otp_expired') ||
      message.contains('auth session missing') ||
      message.contains('jwt expired') ||
      message.contains('token has expired')) {
    return build(FailureCode.authSessionExpired, FailureKind.session);
  }
  if (code.contains('over_request_rate_limit') ||
      code.contains('over_email_send_rate_limit') ||
      error.statusCode == '429') {
    return build(
      FailureCode.unavailable,
      FailureKind.unavailable,
      retryable: true,
    );
  }
  if (code.contains('user_already_exists') || code.contains('email_exists')) {
    return build(FailureCode.validationInvalidInput, FailureKind.validation);
  }
  if (code.contains('weak_password') ||
      code.contains('validation_failed') ||
      code.contains('bad_json')) {
    return build(FailureCode.validationInvalidInput, FailureKind.validation);
  }
  return build(FailureCode.authUnauthorized, FailureKind.authentication);
}

Failure _mapPostgrestException(
  PostgrestException error,
  StackTrace? stackTrace,
) {
  final code = error.code ?? '';
  final message = error.message.toLowerCase();
  Failure build(FailureCode failureCode, FailureKind kind) {
    return Failure(
      code: failureCode,
      message: error.message,
      kind: kind,
      cause: error,
      stackTrace: stackTrace,
      details: <String, Object?>{
        if (error.code != null) 'postgrest_code': error.code!,
        if (error.details != null) 'details': error.details,
        if (error.hint != null) 'hint': error.hint,
      },
    );
  }

  if (code == 'PGRST116' ||
      message.contains('0 rows') ||
      message.contains('no rows')) {
    return build(FailureCode.remoteDatabaseNotFound, FailureKind.database);
  }
  if (code == '23505' || code == '23503') {
    return build(FailureCode.remoteDatabaseConflict, FailureKind.database);
  }
  if (code == '42501' || message.contains('row-level security')) {
    return build(
      FailureCode.remoteDatabaseQueryFailed,
      FailureKind.authorization,
    );
  }
  if (code == 'PGRST301' || code == 'PGRST302' || message.contains('jwt')) {
    return build(FailureCode.authSessionExpired, FailureKind.session);
  }
  if (code == '42P01' ||
      code == 'PGRST204' ||
      code == '42703' ||
      message.contains('does not exist')) {
    return build(FailureCode.remoteDatabaseQueryFailed, FailureKind.validation);
  }
  return build(FailureCode.remoteDatabaseQueryFailed, FailureKind.database);
}

Failure _mapStorageException(
  StorageException error,
  StackTrace? stackTrace,
  FailureCode fallbackCode,
) {
  final status = error.statusCode ?? '';
  final message = error.message.toLowerCase();
  Failure build(FailureCode failureCode, FailureKind kind) {
    return Failure(
      code: failureCode,
      message: error.message,
      kind: kind,
      cause: error,
      stackTrace: stackTrace,
      details: <String, Object?>{
        if (error.statusCode != null) 'status_code': error.statusCode!,
        if (error.error != null) 'storage_error': error.error!,
      },
    );
  }

  if (status == '404' ||
      message.contains('not found') ||
      message.contains('object not found')) {
    return build(FailureCode.fileNotFound, FailureKind.storage);
  }
  if (status == '401' || status == '403' || message.contains('unauthorized')) {
    return build(fallbackCode, FailureKind.authorization);
  }
  if (status == '409' || message.contains('already exists')) {
    return build(fallbackCode, FailureKind.validation);
  }
  return build(fallbackCode, FailureKind.storage);
}

Failure? _networkFailure(Object error, StackTrace? stackTrace) {
  final text = error.toString().toLowerCase();
  const markers = <String>[
    'socketexception',
    'clientexception',
    'failed host lookup',
    'connection refused',
    'connection closed',
    'network is unreachable',
    'xmlhttprequest error',
  ];
  if (!markers.any(text.contains)) {
    return null;
  }
  return Failure(
    code:
        text.contains('connection refused') ||
            text.contains('failed host lookup')
        ? FailureCode.networkUnreachable
        : FailureCode.networkUnknown,
    message: 'The connection to Supabase failed.',
    kind: FailureKind.network,
    cause: error,
    stackTrace: stackTrace,
    isRetryable: true,
  );
}
