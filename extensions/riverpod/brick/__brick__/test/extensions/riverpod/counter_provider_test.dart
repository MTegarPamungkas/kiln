import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/features/counter/counter_provider.dart';

void main() {
  test('counter provider changes and resets', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(counterProvider), 0);

    container.read(counterProvider.notifier).increment();
    container.read(counterProvider.notifier).increment();
    expect(container.read(counterProvider), 2);

    container.read(counterProvider.notifier).decrement();
    expect(container.read(counterProvider), 1);

    container.read(counterProvider.notifier).reset();
    expect(container.read(counterProvider), 0);
  });
}
