import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/features/counter/counter_cubit.dart';

void main() {
  test('counter changes and resets', () {
    final cubit = CounterCubit();

    cubit.increment();
    cubit.increment();
    expect(cubit.state, 2);

    cubit.decrement();
    expect(cubit.state, 1);

    cubit.reset();
    expect(cubit.state, 0);
    cubit.close();
  });
}
