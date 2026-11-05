import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimiter', () {
    test('starts full and consumes tokens', () {
      final clock = FixedClock.at(2026, 11, 1, 12);
      final limiter = RateLimiter(
        capacity: 3,
        refillInterval: const Duration(seconds: 1),
        clock: clock,
      );

      expect(limiter.available, 3);
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isFalse);
      expect(limiter.available, 0);
    });

    test('refills at the configured rate', () {
      final clock = FixedClock.at(2026, 11, 1, 12);
      final limiter = RateLimiter(
        capacity: 2,
        refillInterval: const Duration(seconds: 1),
        clock: clock,
      );

      limiter.tryAcquire(2);
      expect(limiter.tryAcquire(), isFalse);

      clock.advance(const Duration(milliseconds: 500));
      expect(limiter.tryAcquire(), isFalse);

      clock.advance(const Duration(milliseconds: 500));
      expect(limiter.tryAcquire(), isTrue);
    });

    test('never exceeds capacity', () {
      final clock = FixedClock.at(2026, 11, 1, 12);
      final limiter = RateLimiter(
        capacity: 2,
        refillInterval: const Duration(seconds: 1),
        clock: clock,
      );

      clock.advance(const Duration(minutes: 5));
      expect(limiter.available, 2);
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isFalse);
    });

    test('requires multiple tokens for a larger permit', () {
      final clock = FixedClock.at(2026, 11, 1, 12);
      final limiter = RateLimiter(
        capacity: 5,
        refillInterval: const Duration(seconds: 1),
        clock: clock,
      );

      expect(limiter.tryAcquire(3), isTrue);
      expect(limiter.available, 2);
      expect(limiter.tryAcquire(3), isFalse);
      expect(limiter.available, 2);
    });

    test('acquire returns immediately when tokens are available', () async {
      final limiter = RateLimiter(
        capacity: 1,
        refillInterval: const Duration(seconds: 1),
      );

      await limiter.acquire();
    });

    test('acquire waits for a refill when the bucket is empty', () async {
      final limiter = RateLimiter(
        capacity: 1,
        refillInterval: const Duration(milliseconds: 10),
      );

      expect(limiter.tryAcquire(), isTrue);
      final started = DateTime.now();
      await limiter.acquire().timeout(const Duration(seconds: 2));
      expect(
        DateTime.now().difference(started),
        greaterThanOrEqualTo(const Duration(milliseconds: 5)),
      );
    });
  });
}
