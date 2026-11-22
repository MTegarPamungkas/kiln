import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/http_retry/retry_settings.dart';

void main() {
  test('copyWith replaces only the given values', () {
    const base = HttpRetrySettings(
      maxAttempts: 3,
      initialDelay: Duration(milliseconds: 100),
      maxDelay: Duration(seconds: 2),
      jitter: false,
    );

    final copy = base.copyWith(totalBudget: const Duration(seconds: 5));

    expect(copy.totalBudget, const Duration(seconds: 5));
    expect(copy.maxAttempts, 3);
    expect(copy.initialDelay, const Duration(milliseconds: 100));
    expect(copy.maxDelay, const Duration(seconds: 2));
    expect(copy.jitter, isFalse);
    expect(copy.retryableStatusCodes, base.retryableStatusCodes);
  });

  test('a total budget is optional', () {
    const settings = HttpRetrySettings(maxAttempts: 1);

    expect(settings.totalBudget, isNull);
    expect(settings.validate(), isNull);
  });

  test('a negative total budget is rejected', () {
    const settings = HttpRetrySettings(
      maxAttempts: 1,
      totalBudget: Duration(seconds: -1),
    );

    expect(settings.validate(), isNotNull);
  });
}
