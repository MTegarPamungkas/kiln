import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/bloc/async_state.dart';

void main() {
  test('AsyncState variants carry their payloads', () {
    const initial = AsyncInitial<int>();
    const loading = AsyncLoading<int>();
    const data = AsyncData<int>(3);
    const failure = AsyncFailure<int>(
      Failure(code: FailureCode.networkTimeout, message: 'timeout'),
    );

    expect(initial, isA<AsyncInitial<int>>());
    expect(loading, isA<AsyncLoading<int>>());
    expect(data.value, 3);
    expect(failure.failure.code, FailureCode.networkTimeout);
  });
}
