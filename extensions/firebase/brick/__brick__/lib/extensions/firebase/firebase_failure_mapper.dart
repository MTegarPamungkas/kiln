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
      message: 'Permintaan ke Firebase melewati batas waktu.',
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
        'Email atau kata sandi tidak cocok.',
        FailureKind.authentication,
        error,
        stackTrace,
      );
    case 'email-not-verified':
      return _failure(
        FailureCode.authEmailNotVerified,
        'Verifikasi email terlebih dahulu sebelum masuk.',
        FailureKind.authentication,
        error,
        stackTrace,
      );
    case 'too-many-requests':
      return _failure(
        FailureCode.unavailable,
        'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
        FailureKind.unavailable,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'permission-denied':
    case 'user-disabled':
      return _failure(
        FailureCode.authUnauthorized,
        'Akun ini tidak diizinkan mengakses layanan.',
        FailureKind.authorization,
        error,
        stackTrace,
      );
    case 'requires-recent-login':
    case 'user-token-expired':
      return _failure(
        FailureCode.authSessionExpired,
        'Sesi berakhir. Masuk kembali untuk melanjutkan.',
        FailureKind.session,
        error,
        stackTrace,
      );
    case 'network-request-failed':
    case 'unavailable':
      return _failure(
        FailureCode.networkUnreachable,
        'Tidak dapat menghubungi Firebase Auth.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'deadline-exceeded':
      return _failure(
        FailureCode.networkTimeout,
        'Permintaan Firebase Auth melewati batas waktu.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'operation-not-allowed':
      return _failure(
        FailureCode.authProviderDisabled,
        'Metode masuk ini belum diaktifkan di Firebase Console.',
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
        'Proses masuk dibatalkan.',
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
        'Dokumen tidak ditemukan.',
        FailureKind.database,
        error,
        stackTrace,
      );
    case 'already-exists':
    case 'aborted':
      return _failure(
        FailureCode.remoteDatabaseConflict,
        'Dokumen sudah berubah. Muat ulang lalu coba lagi.',
        FailureKind.database,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'permission-denied':
    case 'unauthenticated':
      return _failure(
        FailureCode.authUnauthorized,
        'Aturan keamanan Firestore menolak permintaan ini.',
        FailureKind.authorization,
        error,
        stackTrace,
      );
    case 'unavailable':
      return _failure(
        FailureCode.remoteDatabaseUnavailable,
        'Firestore sedang tidak tersedia.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'deadline-exceeded':
      return _failure(
        FailureCode.networkTimeout,
        'Permintaan Firestore melewati batas waktu.',
        FailureKind.network,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'failed-precondition':
      return _failure(
        FailureCode.remoteDatabaseQueryFailed,
        'Query ditolak Firestore. Periksa indeks komposit yang diminta.',
        FailureKind.validation,
        error,
        stackTrace,
      );
    case 'invalid-argument':
      return _failure(
        FailureCode.validationInvalidInput,
        'Query Firestore tidak valid.',
        FailureKind.validation,
        error,
        stackTrace,
      );
    case 'resource-exhausted':
      return _failure(
        FailureCode.remoteDatabaseUnavailable,
        'Kuota Firestore habis. Coba lagi nanti.',
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
        'Berkas tidak ditemukan di Cloud Storage.',
        FailureKind.file,
        error,
        stackTrace,
      );
    case 'unauthorized':
    case 'unauthenticated':
    case 'permission-denied':
      return _failure(
        FailureCode.authUnauthorized,
        'Aturan keamanan Storage menolak permintaan ini.',
        FailureKind.authorization,
        error,
        stackTrace,
      );
    case 'retry-limit-exceeded':
      return _failure(
        FailureCode.fileUploadFailed,
        'Unggahan gagal setelah beberapa percobaan.',
        FailureKind.file,
        error,
        stackTrace,
        isRetryable: true,
      );
    case 'canceled':
    case 'cancelled':
      return _failure(
        FailureCode.cancelled,
        'Operasi penyimpanan dibatalkan.',
        FailureKind.cancelled,
        error,
        stackTrace,
      );
    case 'quota-exceeded':
      return _failure(
        FailureCode.storageWriteFailed,
        'Kuota Cloud Storage habis.',
        FailureKind.storage,
        error,
        stackTrace,
      );
    case 'invalid-argument':
      return _failure(
        FailureCode.validationInvalidInput,
        'Path atau metadata berkas tidak valid.',
        FailureKind.validation,
        error,
        stackTrace,
      );
    case 'unavailable':
    case 'network-request-failed':
      return _failure(
        FailureCode.networkUnreachable,
        'Tidak dapat menghubungi Cloud Storage.',
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
      'Tidak dapat menghubungi Firebase.',
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
