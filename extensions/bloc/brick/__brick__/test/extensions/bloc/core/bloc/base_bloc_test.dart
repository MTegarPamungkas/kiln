import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/bloc/base_bloc.dart';

enum _TestEvent { incremented, rejected }

final class _TestBloc extends BaseBloc<_TestEvent, int> {
  _TestBloc() : super(0) {
    on<_TestEvent>((event, emit) async {
      if (event == _TestEvent.rejected) {
        reportResult(
          await runGuarded<int>(() => throw StateError('boom')),
          emit,
          (failure) => 100,
        );
        return;
      }
      emit(state + 1);
    });
  }
}

void main() {
  test('runGuarded converts a throw into an Err', () async {
    final bloc = _TestBloc();

    final result = await bloc.runGuarded<int>(
      () => throw StateError('boom'),
    );

    expect(result, isA<Err<int>>());
    expect(result.failureOrNull, isA<Failure>());
    expect(result.isOk, isFalse);
    await bloc.close();
  });

  test('runGuarded keeps a successful value', () async {
    final bloc = _TestBloc();

    final result = await bloc.runGuarded<int>(() async => 5);

    expect(result, isA<Ok<int>>());
    expect(result.valueOrNull, 5);
    await bloc.close();
  });

  test('reportResult only emits for a failure', () async {
    final bloc = _TestBloc();
    final states = <int>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(_TestEvent.incremented);
    await Future<void>.delayed(Duration.zero);
    bloc.add(_TestEvent.rejected);
    await Future<void>.delayed(Duration.zero);

    expect(states, <int>[1, 100]);
    await subscription.cancel();
    await bloc.close();
  });

  test('a guarded throw never escapes the handler', () async {
    final bloc = _TestBloc();

    bloc.add(_TestEvent.rejected);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, 100);
    await bloc.close();
  });
}
