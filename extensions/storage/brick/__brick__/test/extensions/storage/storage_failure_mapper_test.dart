import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/storage/storage_failure_mapper.dart';

void main() {
  test('wraps errors with a storage failure', () {
    final failure = mapStorageError(StateError('broken'));

    expect(failure.code, FailureCode.storageReadFailed);
    expect(failure.kind, FailureKind.storage);
    expect(failure.cause, isA<StateError>());
  });

  test('keeps an existing Failure', () {
    const original = Failure(
      code: FailureCode.storageWriteFailed,
      message: 'write',
      kind: FailureKind.storage,
    );

    expect(mapStorageError(original), same(original));
  });
}
