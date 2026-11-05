import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/http_retry/retry_budget.dart';

void main() {
  test('limits retries in a rolling window and resets after it', () {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final budget = RetryBudget(
      maxRetries: 2,
      window: const Duration(seconds: 10),
      clock: clock,
    );

    expect(budget.tryConsume('/users'), isTrue);
    expect(budget.tryConsume('/users'), isTrue);
    expect(budget.tryConsume('/users'), isFalse);
    expect(budget.remaining('/users'), 0);

    clock.advance(const Duration(seconds: 11));
    expect(budget.tryConsume('/users'), isTrue);
    expect(budget.remaining('/users'), 1);
  });

  test('keeps budgets per key', () {
    final budget = RetryBudget(maxRetries: 1);

    expect(budget.tryConsume('/a'), isTrue);
    expect(budget.tryConsume('/a'), isFalse);
    expect(budget.tryConsume('/b'), isTrue);
  });
}
