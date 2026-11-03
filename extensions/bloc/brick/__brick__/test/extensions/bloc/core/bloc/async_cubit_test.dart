import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/core/bloc/async_cubit.dart';
import 'package:{{app_name}}/core/bloc/async_state.dart';

void main() {
  test('load emits loading then data', () async {
    final cubit = AsyncCubit<int>(() async => 42);
    final states = <AsyncState<int>>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<AsyncLoading<int>>());
    expect((states[1] as AsyncData<int>).value, 42);
    await subscription.cancel();
    await cubit.close();
  });

  test('a failure becomes AsyncFailure', () async {
    final cubit = AsyncCubit<int>(() async => throw StateError('broken'));

    await cubit.load();

    expect(cubit.state, isA<AsyncFailure<int>>());
    await cubit.close();
  });
}
