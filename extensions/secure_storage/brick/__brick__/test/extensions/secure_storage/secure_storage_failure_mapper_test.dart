import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_storage_failure_mapper.dart';

void main() {
  test('wraps plugin errors as secure storage failures', () {
    final failure = mapSecureStorageError(StateError('broken'));

    expect(failure.code, FailureCode.secureStorageReadFailed);
    expect(failure.kind, FailureKind.storage);
  });

  test('keeps an existing Failure', () {
    const original = Failure(
      code: FailureCode.secureStorageUnavailable,
      message: 'unavailable',
      kind: FailureKind.storage,
    );

    expect(mapSecureStorageError(original), same(original));
  });
}
