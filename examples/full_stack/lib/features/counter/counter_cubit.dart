import 'package:full_stack/core/bloc/base_cubit.dart';

/// Example Cubit used by the generated application.
final class CounterCubit extends BaseCubit<int> {
  CounterCubit() : super(0);

  void increment() => safeEmit(state + 1);

  void decrement() => safeEmit(state - 1);

  void reset() => safeEmit(0);
}
