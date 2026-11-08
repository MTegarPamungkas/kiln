import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/core/bloc/app_bloc_observer.dart';

final class _NoopObserver extends BlocObserver {
  const _NoopObserver();
}

enum _TestEvent { incremented }

final class _TestBloc extends Bloc<_TestEvent, int> {
  _TestBloc() : super(0) {
    on<_TestEvent>((event, emit) => emit(1));
  }
}

void main() {
  test('observer logs transitions', () async {
    final logger = RecordingLogger();
    Bloc.observer = AppBlocObserver(logger: logger);

    final bloc = _TestBloc();
    bloc.add(_TestEvent.incremented);
    await Future<void>.delayed(Duration.zero);

    expect(logger.messages.join('\n'), contains('bloc _TestBloc'));
    await bloc.close();
    Bloc.observer = const _NoopObserver();
  });
}
