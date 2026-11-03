import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/deep_link/pending_link_buffer.dart';

void main() {
  final first = Uri.parse('https://kiln.dev/profile/1');
  final second = Uri.parse('https://kiln.dev/profile/2');
  final third = Uri.parse('https://kiln.dev/profile/3');

  test('buffers links in arrival order', () {
    final buffer = PendingLinkBuffer();

    buffer
      ..add(first)
      ..add(second);

    expect(buffer.isBuffering, isTrue);
    expect(buffer.hasPending, isTrue);
    expect(buffer.length, 2);
    expect(buffer.pending, <Uri>[first, second]);
  });

  test('keeps the newest links when the capacity is reached', () {
    final buffer = PendingLinkBuffer(capacity: 2);

    buffer
      ..add(first)
      ..add(second)
      ..add(third);

    expect(buffer.pending, <Uri>[second, third]);
  });

  test('releases the buffered links once', () {
    final buffer = PendingLinkBuffer()
      ..add(first)
      ..add(second);

    expect(buffer.release(), <Uri>[first, second]);
    expect(buffer.isBuffering, isFalse);
    expect(buffer.hasPending, isFalse);

    buffer.add(third);
    expect(buffer.release(), isEmpty);
  });

  test('an empty release also stops buffering', () {
    final buffer = PendingLinkBuffer();

    expect(buffer.release(), isEmpty);
    buffer.add(first);

    expect(buffer.hasPending, isFalse);
  });

  test('clear drops buffered links without releasing', () {
    final buffer = PendingLinkBuffer()..add(first);

    buffer.clear();

    expect(buffer.hasPending, isFalse);
    expect(buffer.isBuffering, isTrue);
  });
}
