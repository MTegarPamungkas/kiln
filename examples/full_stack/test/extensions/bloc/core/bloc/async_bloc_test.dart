import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/core/bloc/async_bloc.dart';
import 'package:full_stack/core/bloc/async_state.dart';

Future<void> _idle() => Future<void>.delayed(Duration.zero);

void main() {
  test('auto load walks loading into data', () async {
    final bloc = AsyncBloc<int>(() async => 7);
    final states = <AsyncState<int>>[];
    final subscription = bloc.stream.listen(states.add);
    await _idle();

    expect(states.whereType<AsyncLoading<int>>(), isNotEmpty);
    expect(bloc.state, isA<AsyncData<int>>());
    expect((bloc.state as AsyncData<int>).value, 7);

    await subscription.cancel();
    await bloc.close();
  });

  test('a throwing fetcher becomes a typed failure state', () async {
    final bloc = AsyncBloc<int>(() => throw StateError('offline'));
    await _idle();

    expect(bloc.state, isA<AsyncFailure<int>>());
    final failure = (bloc.state as AsyncFailure<int>).failure;
    expect(failure.kind, FailureKind.unknown);

    await bloc.close();
  });

  test('refresh reloads after data arrived', () async {
    var calls = 0;
    final bloc = AsyncBloc<int>(() async {
      calls++;
      return calls;
    });
    await _idle();
    expect((bloc.state as AsyncData<int>).value, 1);

    bloc.refresh();
    await _idle();

    expect(calls, 2);
    expect((bloc.state as AsyncData<int>).value, 2);
    await bloc.close();
  });

  test('autoLoad false waits for the caller', () async {
    var calls = 0;
    final bloc = AsyncBloc<int>(
      () async => calls++,
      autoLoad: false,
    );
    await _idle();

    expect(calls, 0);
    expect(bloc.state, isA<AsyncInitial<int>>());

    bloc.retry();
    await _idle();
    expect(calls, 1);

    await bloc.close();
  });
}
