import 'package:appwrite/appwrite.dart';
import 'package:kiln_core/kiln_core.dart';

/// Contract area an Appwrite error came from.
enum AppwriteFailureScope { auth, account, database, storage, realtime, functions }

/// Converts Appwrite and transport exceptions into contract failures.
final class AppwriteFailureMapper {
  const AppwriteFailureMapper();

  /// Maps [error] while keeping the original exception as the failure cause.
  Failure map(
    Object error, {
    AppwriteFailureScope scope = AppwriteFailureScope.auth,
    StackTrace? stackTrace,
  }) {
    if (error is Failure) {
      return error;
    }
    if (error is! AppwriteException) {
      return _transport(error, scope, stackTrace);
    }

    final status = error.code;
    if (status == null || status == 0) {
      final message = error.message?.toLowerCase() ?? '';
      if (message.contains('missing required parameter') ||
          message.contains('invalid endpoint') ||
          message.contains('path parameter cannot')) {
        return _build(
          code: FailureCode.validationInvalidInput,
          message: _message(error, 'Appwrite rejected the request locally.'),
          kind: FailureKind.validation,
          error: error,
          stackTrace: stackTrace,
        );
      }
      return _transport(error, scope, stackTrace);
    }

    if (status == 400) {
      return _build(
        code: FailureCode.validationInvalidInput,
        message: _message(error, 'Appwrite rejected the request.'),
        kind: FailureKind.validation,
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (status == 401) {
      return _unauthorized(error, stackTrace);
    }
    if (status == 403) {
      return _build(
        code: FailureCode.permissionDenied,
        message: _message(error, 'Appwrite denied this operation.'),
        kind: FailureKind.permission,
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (status == 404) {
      return switch (scope) {
        AppwriteFailureScope.database ||
        AppwriteFailureScope.realtime => _build(
          code: FailureCode.remoteDatabaseNotFound,
          message: _message(error, 'The requested document does not exist.'),
          kind: FailureKind.database,
          error: error,
          stackTrace: stackTrace,
        ),
        AppwriteFailureScope.storage => _build(
          code: FailureCode.fileNotFound,
          message: _message(error, 'The requested file does not exist.'),
          kind: FailureKind.file,
          error: error,
          stackTrace: stackTrace,
        ),
        AppwriteFailureScope.auth || AppwriteFailureScope.account => _build(
          code: FailureCode.authUnauthorized,
          message: _message(error, 'The account is not available.'),
          kind: FailureKind.authentication,
          error: error,
          stackTrace: stackTrace,
        ),
        AppwriteFailureScope.functions => _build(
          code: FailureCode.functionsNotFound,
          message: _message(error, 'The requested function does not exist.'),
          kind: FailureKind.unknown,
          error: error,
          stackTrace: stackTrace,
        ),
      };
    }
    if (status == 409) {
      return switch (scope) {
        AppwriteFailureScope.database ||
        AppwriteFailureScope.realtime => _build(
          code: FailureCode.remoteDatabaseConflict,
          message: _message(
            error,
            'The document conflicts with an existing one.',
          ),
          kind: FailureKind.database,
          error: error,
          stackTrace: stackTrace,
        ),
        AppwriteFailureScope.storage => _build(
          code: FailureCode.fileUploadFailed,
          message: _message(error, 'The file conflicts with an existing one.'),
          kind: FailureKind.file,
          error: error,
          stackTrace: stackTrace,
        ),
        AppwriteFailureScope.auth || AppwriteFailureScope.account => _build(
          code: FailureCode.validationInvalidInput,
          message: _message(error, 'The account already exists.'),
          kind: FailureKind.validation,
          error: error,
          stackTrace: stackTrace,
        ),
        AppwriteFailureScope.functions => _build(
          code: FailureCode.unexpected,
          message: _message(error, 'The function execution conflicts.'),
          kind: FailureKind.unknown,
          error: error,
          stackTrace: stackTrace,
        ),
      };
    }
    if (status == 413) {
      return _build(
        code: scope == AppwriteFailureScope.storage
            ? FailureCode.fileUploadFailed
            : FailureCode.validationInvalidInput,
        message: _message(error, 'The payload is too large for Appwrite.'),
        kind: scope == AppwriteFailureScope.storage
            ? FailureKind.file
            : FailureKind.validation,
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (status == 429) {
      return _build(
        code: FailureCode.networkServer,
        message: _message(error, 'Appwrite rate limit reached.'),
        kind: FailureKind.network,
        error: error,
        stackTrace: stackTrace,
        isRetryable: true,
      );
    }
    if (status >= 500) {
      return _build(
        code: FailureCode.unavailable,
        message: _message(error, 'Appwrite is temporarily unavailable.'),
        kind: _kindFor(scope),
        error: error,
        stackTrace: stackTrace,
        isRetryable: true,
      );
    }

    return _build(
      code: FailureCode.unexpected,
      message: _message(error, 'Appwrite request failed.'),
      kind: _kindFor(scope),
      error: error,
      stackTrace: stackTrace,
    );
  }

  Failure _unauthorized(AppwriteException error, StackTrace? stackTrace) {
    final type = error.type?.toLowerCase() ?? '';
    final message = error.message?.toLowerCase() ?? '';
    if (type.contains('invalid_credentials') ||
        message.contains('invalid credentials')) {
      return _build(
        code: FailureCode.authInvalidCredentials,
        message: _message(error, 'The email or password is incorrect.'),
        kind: FailureKind.authentication,
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (type.contains('email_not_verified') ||
        message.contains('not verified')) {
      return _build(
        code: FailureCode.authEmailNotVerified,
        message: _message(error, 'Verify the email address first.'),
        kind: FailureKind.authentication,
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (type.contains('session') || message.contains('session')) {
      return _build(
        code: FailureCode.authSessionExpired,
        message: _message(error, 'The Appwrite session has expired.'),
        kind: FailureKind.authentication,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return _build(
      code: FailureCode.authUnauthorized,
      message: _message(error, 'Sign in to continue.'),
      kind: FailureKind.authentication,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Failure _transport(
    Object error,
    AppwriteFailureScope scope,
    StackTrace? stackTrace,
  ) {
    final description = error is AppwriteException
        ? _message(error, 'Appwrite network request failed.')
        : error.toString();
    final lowered = description.toLowerCase();
    final unreachable = _unreachableMarkers.any(lowered.contains);
    return Failure(
      code: unreachable
          ? FailureCode.networkUnreachable
          : FailureCode.networkUnknown,
      message: description,
      kind: FailureKind.network,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: true,
      details: <String, Object?>{'scope': scope.name},
    );
  }

  Failure _build({
    required FailureCode code,
    required String message,
    required FailureKind kind,
    required AppwriteException error,
    StackTrace? stackTrace,
    bool isRetryable = false,
  }) {
    return Failure(
      code: code,
      message: message,
      kind: kind,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: isRetryable,
      details: <String, Object?>{
        if (error.code != null) 'appwriteCode': error.code,
        if (error.type != null) 'appwriteType': error.type,
      },
    );
  }

  FailureKind _kindFor(AppwriteFailureScope scope) {
    return switch (scope) {
      AppwriteFailureScope.auth ||
      AppwriteFailureScope.account => FailureKind.authentication,
      AppwriteFailureScope.database ||
      AppwriteFailureScope.realtime => FailureKind.database,
      AppwriteFailureScope.storage => FailureKind.file,
      AppwriteFailureScope.functions => FailureKind.unknown,
    };
  }

  String _message(AppwriteException error, String fallback) {
    final message = error.message?.trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  static const List<String> _unreachableMarkers = <String>[
    'socketexception',
    'clientexception',
    'failed host lookup',
    'connection refused',
    'connection reset',
    'network is unreachable',
    'xmlhttprequest error',
  ];
}
