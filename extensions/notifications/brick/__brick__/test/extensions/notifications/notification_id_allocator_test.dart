import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/notifications/notification_id_allocator.dart';

void main() {
  test('ids are stable and positive', () {
    const allocator = NotificationIdAllocator();

    final first = allocator.idFor('daily-reminder');
    final second = allocator.idFor('daily-reminder');

    expect(first, second);
    expect(first, greaterThanOrEqualTo(0));
    expect(first, lessThan(0x80000000));
  });

  test('different keys produce different ids', () {
    const allocator = NotificationIdAllocator();

    expect(allocator.idFor('a'), isNot(allocator.idFor('b')));
    expect(allocator.idFor('orders/42'), isNot(allocator.idFor('orders/24')));
  });
}
