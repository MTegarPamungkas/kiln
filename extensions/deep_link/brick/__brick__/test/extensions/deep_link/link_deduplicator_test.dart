import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/deep_link/link_deduplicator.dart';

void main() {
  final link = Uri.parse('https://kiln.dev/profile/42');

  test('accepts a link the first time', () {
    final clock = FixedClock.at(2026, 11, 2, 9);
    final deduplicator = LinkDeduplicator(clock: clock);

    expect(deduplicator.isDuplicate(link), isFalse);
  });

  test('ignores the same link inside the window', () {
    final clock = FixedClock.at(2026, 11, 2, 9);
    final deduplicator = LinkDeduplicator(
      clock: clock,
      window: const Duration(seconds: 2),
    );

    deduplicator.isDuplicate(link);

    expect(deduplicator.isDuplicate(link), isTrue);
    clock.advance(const Duration(seconds: 2));
    expect(deduplicator.isDuplicate(link), isTrue);
    clock.advance(const Duration(milliseconds: 1));
    expect(deduplicator.isDuplicate(link), isFalse);
  });

  test('accepts different links inside the window', () {
    final clock = FixedClock.at(2026, 11, 2, 9);
    final deduplicator = LinkDeduplicator(clock: clock);

    expect(deduplicator.isDuplicate(link), isFalse);
    expect(
      deduplicator.isDuplicate(Uri.parse('https://kiln.dev/profile/43')),
      isFalse,
    );
  });

  test('clear forgets recorded links', () {
    final clock = FixedClock.at(2026, 11, 2, 9);
    final deduplicator = LinkDeduplicator(clock: clock);

    deduplicator.isDuplicate(link);
    deduplicator.clear();

    expect(deduplicator.isDuplicate(link), isFalse);
  });
}
