import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/core/bloc/app_bloc_observer.dart';

final class _NoopObserver extends BlocObserver {
  const _NoopObserver();
}

final class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);
}

void main() {
  test('observer logs transitions', () {
    final logger = RecordingLogger();
    Bloc.observer = AppBlocObserver(logger: logger);

    final cubit = _TestCubit()..emit(1);

    expect(logger.messages.join('\n'), contains('bloc _TestCubit'));
    cubit.close();
    Bloc.observer = const _NoopObserver();
  });
}
