import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:kiln_core/kiln_core.dart';

/// Converts any error raised by a Firebase SDK into a [Failure].
///
/// Every contract implementation funnels errors through this function so
/// callers only ever see Kiln failure codes, never SDK exceptions.
typedef FirebaseFailureMapper = Failure Function(
  Object error,
  StackTrace? stackTrace,
);

/// Maps SDK errors to the closest Kiln failure.
Failure mapFirebaseError(Object error, [StackTrace? stackTrace]) {
  if (error is Failure) {
    return error;
  }
  if (error is FirebaseException) {
    return _mapFirebaseException(error, stackTrace);
  }
  if (error is TimeoutException) {
    return Failure(
      code: FailureCode.networkTimeout,
      message: 'The request to Firebase timed out.',
      kind: FailureKind.network,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }
  return Failure.from(
    error,
    code: FailureCode.unexpected,
    kind: FailureKind.unknown,
    stackTrace: stackTrace,
  );
}

Failure _mapFirebaseException(FirebaseException error, StackTrace? stackTrace) {
  final plugin = error.plugin.toLowerCase();
  final code = error.code.toLowerCase();
  if (plugin.contains('firestore')) {
    return _mapFirestore(error, code, stackTrace);
  }
  if (plugin.contains('storage')) {
    return _mapStorage(error, code, stackTrace);
  }
  if (plugin.contains('auth')) {
    return _mapAuth(error, code, stackTrace);
  }
  return _mapCore(error, code, stackTrace);
}

Failure _mapAuth(FirebaseException error, String code, StackTrace? stackTrace) {
  switch (code) {
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
    case 'user-not-found':
    case 'invalid-email':
    case 'account-exists-with-different-credential':
    case 'credential-already-in-use':
    case 'email-already-in-use':
      return _failure(
        FailureCode.authInvalidCredentials,
        'The email or password does not match.',
        FailureKind.authentication,
        error,
        stackTrace,
      );
    case 'email-not-verified':
      return _failure(
        FailureCode.authEmailNotVerified,
        'Verify your email before signing in.',
        FailureKind.authentication,
        error,
        stackTrace,
      );
    case 'too-many-requests':
      return _failure(
        FailureCode.unavailable,
        'Too many attempts. Try again in a while.',
        FailureKind.unavailable,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'permission-denied':
    case 'user-disabled':
      return _failure(
        FailureCode.authUnauthorized,
        'This account is not allowed to access the service.',
        FailureKind.authorization,
        error,
        stackTrace,
      );
    case 'requires-recent-login':
    case 'user-token-expired':
      return _failure(
        FailureCode.authSessionExpired,
        'The session expired. Sign in again to continue.',
        FailureKind.session,
        error,
        stackTrace,
      );
    case 'network-request-failed':
    case 'unavailable':
      return _failure(
        FailureCode.networkUnreachable,
        'Could not reach Firebase Auth.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'deadline-exceeded':
      return _failure(
        FailureCode.networkTimeout,
        'The Firebase Auth request timed out.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'operation-not-allowed':
      return _failure(
        FailureCode.authProviderDisabled,
        'This sign-in method is not enabled in the Firebase Console.',
        FailureKind.authentication,
        error,
        stackTrace,
      );
    case 'popup-closed-by-user':
    case 'web-context-cancelled':
    case 'cancelled':
    case 'canceled':
      return _failure(
        FailureCode.authCancelled,
        'Sign-in was cancelled.',
        FailureKind.cancelled,
        error,
        stackTrace,
      );
    default:
      return Failure.from(
        error,
        code: FailureCode.unexpected,
        kind: FailureKind.authentication,
        stackTrace: stackTrace,
      );
  }
}

Failure _mapFirestore(
  FirebaseException error,
  String code,
  StackTrace? stackTrace,
) {
  switch (code) {
    case 'not-found':
      return _failure(
        FailureCode.remoteDatabaseNotFound,
        'The document was not found.',
        FailureKind.database,
        error,
        stackTrace,
      );
    case 'already-exists':
    case 'aborted':
      return _failure(
        FailureCode.remoteDatabaseConflict,
        'The document changed. Reload and try again.',
        FailureKind.database,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'permission-denied':
    case 'unauthenticated':
      return _failure(
        FailureCode.authUnauthorized,
        'Firestore security rules rejected this request.',
        FailureKind.authorization,
        error,
        stackTrace,
      );
    case 'unavailable':
      return _failure(
        FailureCode.remoteDatabaseUnavailable,
        'Firestore is currently unavailable.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'deadline-exceeded':
      return _failure(
        FailureCode.networkTimeout,
        'The Firestore request timed out.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'failed-precondition':
      return _failure(
        FailureCode.remoteDatabaseQueryFailed,
        'Firestore rejected the query. Check the required composite index.',
        FailureKind.validation,
        error,
        stackTrace,
      );
    case 'invalid-argument':
      return _failure(
        FailureCode.validationInvalidInput,
        'The Firestore query is not valid.',
        FailureKind.validation,
        error,
        stackTrace,
      );
    case 'resource-exhausted':
      return _failure(
        FailureCode.remoteDatabaseUnavailable,
        'Firestore quota exhausted. Try again later.',
        FailureKind.unavailable,
        error,
        stackTrace,
        isRetryable: true,
      );
    default:
      return Failure.from(
        error,
        code: FailureCode.remoteDatabaseQueryFailed,
        kind: FailureKind.database,
        stackTrace: stackTrace,
      );
  }
}

Failure _mapStorage(
  FirebaseException error,
  String code,
  StackTrace? stackTrace,
) {
  switch (code) {
    case 'object-not-found':
      return _failure(
        FailureCode.fileNotFound,
        'The file was not found in Cloud Storage.',
        FailureKind.file,
        error,
        stackTrace,
      );
    case 'unauthorized':
    case 'unauthenticated':
    case 'permission-denied':
      return _failure(
        FailureCode.authUnauthorized,
        'Storage security rules rejected this request.',
        FailureKind.authorization,
        error,
        stackTrace,
      );
    case 'retry-limit-exceeded':
      return _failure(
        FailureCode.fileUploadFailed,
        'The upload failed after several attempts.',
        FailureKind.file,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'canceled':
    case 'cancelled':
      return _failure(
        FailureCode.cancelled,
        'The storage operation was cancelled.',
        FailureKind.cancelled,
        error,
        stackTrace,
      );
    case 'quota-exceeded':
      return _failure(
        FailureCode.storageWriteFailed,
        'Cloud Storage quota exhausted.',
        FailureKind.storage,
        error,
        stackTrace,
      );
    case 'invalid-argument':
      return _failure(
        FailureCode.validationInvalidInput,
        'The file path or metadata is not valid.',
        FailureKind.validation,
        error,
        stackTrace,
      );
    case 'unavailable':
    case 'network-request-failed':
      return _failure(
        FailureCode.networkUnreachable,
        'Could not reach Cloud Storage.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    default:
      return Failure.from(
        error,
        code: FailureCode.unexpected,
        kind: FailureKind.storage,
        stackTrace: stackTrace,
      );
  }
}

Failure _mapCore(FirebaseException error, String code, StackTrace? stackTrace) {
  if (code == 'network-request-failed') {
    return _failure(
      FailureCode.networkUnreachable,
      'Could not reach Firebase.',
      FailureKind.network,
      error,
      stackTrace,
      isRetryable: true,
    );
  }
  return Failure.from(
    error,
    code: FailureCode.unexpected,
    kind: FailureKind.unknown,
    stackTrace: stackTrace,
  );
}

Failure _failure(
  FailureCode code,
  String message,
  FailureKind kind,
  Object error,
  StackTrace? stackTrace, {
  bool isRetryable = false,
}) {
  return Failure(
    code: code,
    message: message,
    kind: kind,
    cause: error,
    stackTrace: stackTrace,
    isRetryable: isRetryable,
  );
}
