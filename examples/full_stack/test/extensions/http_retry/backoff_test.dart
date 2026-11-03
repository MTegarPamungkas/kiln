import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/http_retry/backoff.dart';
import 'package:full_stack/extensions/http_retry/retry_settings.dart';

void main() {
  test('grows exponentially and respects the cap without jitter', () {
    final backoff = Backoff(
      settings: const HttpRetrySettings(
        maxAttempts: 6,
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(milliseconds: 1000),
        jitter: false,
      ),
    );

    expect(backoff.delayFor(1), const Duration(milliseconds: 100));
    expect(backoff.delayFor(2), const Duration(milliseconds: 200));
    expect(backoff.delayFor(3), const Duration(milliseconds: 400));
    expect(backoff.delayFor(4), const Duration(milliseconds: 800));
    expect(backoff.delayFor(5), const Duration(milliseconds: 1000));
    expect(backoff.delayFor(9), const Duration(milliseconds: 1000));
  });

  test('jitter stays within the configured range', () {
    final backoff = Backoff(
      settings: const HttpRetrySettings(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(seconds: 5),
        jitter: true,
      ),
      random: Random(7),
    );

    for (var index = 0; index < 20; index++) {
      final delay = backoff.delayFor(1).inMilliseconds;
      expect(delay, inInclusiveRange(80, 120));
    }
  });
}
