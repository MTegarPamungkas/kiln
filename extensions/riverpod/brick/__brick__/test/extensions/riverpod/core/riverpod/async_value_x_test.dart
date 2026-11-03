import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/riverpod/async_value_x.dart';

void main() {
  test('failureOrNull exposes the Failure from AsyncError', () {
    final error = AsyncValue<int>.error(
      const Failure(code: FailureCode.networkTimeout, message: 'timeout'),
      StackTrace.empty,
    );

    expect(error.failureOrNull?.code, FailureCode.networkTimeout);
    expect(AsyncValue<int>.data(1).failureOrNull, isNull);
  });

  test('guard converts a thrown error to Err', () async {
    final result = await AsyncValue<int>.data(1)
        .guard<int>(() => throw StateError('broken'));

    expect(result.failureOrNull, isNotNull);
  });
}
