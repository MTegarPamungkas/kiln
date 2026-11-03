import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/core/bloc/app_bloc_observer.dart';
import 'package:{{app_name}}/features/counter/counter_cubit.dart';

final class _NoopObserver extends BlocObserver {
  const _NoopObserver();
}

void main() {
  test('observer logs transitions', () {
    final logger = RecordingLogger();
    Bloc.observer = AppBlocObserver(logger: logger);

    final cubit = CounterCubit()..increment();

    expect(logger.messages.join('\n'), contains('bloc CounterCubit'));
    cubit.close();
    Bloc.observer = const _NoopObserver();
  });
}
