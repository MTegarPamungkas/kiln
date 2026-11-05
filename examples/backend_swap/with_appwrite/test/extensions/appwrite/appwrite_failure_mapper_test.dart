import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_failure_mapper.dart';

void main() {
  const mapper = AppwriteFailureMapper();

  test('401 without credentials becomes an unauthorized failure', () {
    final failure = mapper.map(
      AppwriteException('Missing scope', 401, 'general_unauthorized_scope'),
      scope: AppwriteFailureScope.auth,
    );

    expect(failure.code, FailureCode.authUnauthorized);
    expect(failure.kind, FailureKind.authentication);
  });

  test('401 credentials errors keep the invalid credentials code', () {
    final failure = mapper.map(
      AppwriteException('Invalid credentials', 401, 'user_invalid_credentials'),
      scope: AppwriteFailureScope.auth,
    );

    expect(failure.code, FailureCode.authInvalidCredentials);
  });

  test('401 session errors become session expired', () {
    final failure = mapper.map(
      AppwriteException(
        'The current session is not valid.',
        401,
        'user_session_not_found',
      ),
      scope: AppwriteFailureScope.auth,
    );

    expect(failure.code, FailureCode.authSessionExpired);
  });

  test('404 maps to the not found code of the calling contract', () {
    final database = mapper.map(
      AppwriteException('Not found', 404, 'row_not_found'),
      scope: AppwriteFailureScope.database,
    );
    final storage = mapper.map(
      AppwriteException('Not found', 404, 'storage_file_not_found'),
      scope: AppwriteFailureScope.storage,
    );

    expect(database.code, FailureCode.remoteDatabaseNotFound);
    expect(database.kind, FailureKind.database);
    expect(storage.code, FailureCode.fileNotFound);
    expect(storage.kind, FailureKind.file);
  });

  test('409 maps to a conflict', () {
    final database = mapper.map(
      AppwriteException('Conflict', 409),
      scope: AppwriteFailureScope.database,
    );
    final storage = mapper.map(
      AppwriteException('Conflict', 409),
      scope: AppwriteFailureScope.storage,
    );

    expect(database.code, FailureCode.remoteDatabaseConflict);
    expect(storage.code, FailureCode.fileUploadFailed);
  });

  test('429 is retryable', () {
    final failure = mapper.map(
      AppwriteException('Too many requests', 429),
      scope: AppwriteFailureScope.database,
    );

    expect(failure.code, FailureCode.networkServer);
    expect(failure.kind, FailureKind.network);
    expect(failure.isRetryable, isTrue);
  });

  test('transport errors become retryable network failures', () {
    final unreachable = mapper.map(
      AppwriteException('SocketException: Failed host lookup'),
      scope: AppwriteFailureScope.auth,
    );
    final unknown = mapper.map(
      AppwriteException('Something odd happened'),
      scope: AppwriteFailureScope.auth,
    );

    expect(unreachable.code, FailureCode.networkUnreachable);
    expect(unreachable.isRetryable, isTrue);
    expect(unknown.code, FailureCode.networkUnknown);
  });

  test('server errors become unavailable failures', () {
    final failure = mapper.map(
      AppwriteException('Server exploded', 503),
      scope: AppwriteFailureScope.database,
    );

    expect(failure.code, FailureCode.unavailable);
    expect(failure.kind, FailureKind.database);
    expect(failure.isRetryable, isTrue);
  });

  test('unknown errors keep the calling contract kind', () {
    final failure = mapper.map(
      AppwriteException('Teapot', 418),
      scope: AppwriteFailureScope.storage,
    );

    expect(failure.code, FailureCode.unexpected);
    expect(failure.kind, FailureKind.file);
  });

  test('an existing Failure is returned unchanged', () {
    const original = Failure(
      code: FailureCode.validationInvalidInput,
      message: 'bad input',
      kind: FailureKind.validation,
    );

    expect(mapper.map(original), same(original));
  });
}
