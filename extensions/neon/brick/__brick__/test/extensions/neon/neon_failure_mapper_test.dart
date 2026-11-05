import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_failure_mapper.dart';
import 'package:{{app_name}}/extensions/neon/neon_gateway.dart';

void main() {
  test('a 404 maps to remote database not found', () {
    final failure = mapNeonError(
      const NeonApiException('no rows', statusCode: 404),
    );

    expect(failure.code, FailureCode.remoteDatabaseNotFound);
    expect(failure.kind, FailureKind.database);
    expect(failure.details['statusCode'], 404);
  });

  test('a server error maps to unavailable', () {
    final failure = mapNeonError(
      const NeonApiException('boom', statusCode: 503, code: 'PGRST000'),
    );

    expect(failure.code, FailureCode.remoteDatabaseUnavailable);
    expect(failure.details['code'], 'PGRST000');
  });

  test('a client error maps to query failed', () {
    final failure = mapNeonError(
      const NeonApiException('bad filter', statusCode: 400),
    );

    expect(failure.code, FailureCode.remoteDatabaseQueryFailed);
  });

  test('a missing status falls back to the provided code', () {
    final failure = mapNeonError(
      const NeonApiException('timeout'),
      fallbackCode: FailureCode.remoteDatabaseQueryFailed,
    );

    expect(failure.code, FailureCode.remoteDatabaseQueryFailed);
  });

  test('a generic error uses the fallback code and kind', () {
    final failure = mapNeonError(
      StateError('socket closed'),
      fallbackCode: FailureCode.remoteDatabaseUnavailable,
      fallbackKind: FailureKind.network,
    );

    expect(failure.code, FailureCode.remoteDatabaseUnavailable);
    expect(failure.kind, FailureKind.network);
  });

  test('a Failure passes through untouched', () {
    const original = Failure(
      code: FailureCode.validationInvalidInput,
      message: 'keep me',
      kind: FailureKind.validation,
    );

    expect(mapNeonError(original), same(original));
  });
}
