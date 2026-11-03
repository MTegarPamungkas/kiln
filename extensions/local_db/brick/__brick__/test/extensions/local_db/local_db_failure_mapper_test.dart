import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/local_db/local_db_failure_mapper.dart';

void main() {
  test('wraps errors as database failures', () {
    final failure = mapLocalDbError(StateError('broken'));

    expect(failure.code, FailureCode.databaseQueryFailed);
    expect(failure.kind, FailureKind.database);
  });

  test('keeps an existing Failure', () {
    const original = Failure(
      code: FailureCode.databaseNotFound,
      message: 'missing',
      kind: FailureKind.database,
    );

    expect(mapLocalDbError(original), same(original));
  });
}
