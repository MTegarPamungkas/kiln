import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/notifications/notification_id_allocator.dart';
import 'package:{{app_name}}/extensions/notifications/reminder_scheduler.dart';

void main() {
  test('scheduling the same reminder twice is idempotent', () async {
    final notifications = FakeNotifications();
    const allocator = NotificationIdAllocator();
    final scheduler = ReminderScheduler(
      notifications: notifications,
      allocator: allocator,
    );
    final when = DateTime.utc(2026, 11, 2, 9);

    expect(
      await scheduler.schedule(
        key: 'daily',
        title: 'Hari baru',
        body: 'Catat pengeluaran',
        when: when,
      ),
      isTrue,
    );
    expect(
      await scheduler.schedule(
        key: 'daily',
        title: 'Hari baru',
        body: 'Catat pengeluaran',
        when: when,
      ),
      isFalse,
    );

    expect(notifications.scheduled, hasLength(1));
    expect(notifications.scheduled.single.message.id, allocator.idFor('daily'));
    expect(scheduler.scheduledKeys, {'daily'});
  });

  test('changing the instant replaces the reminder', () async {
    final notifications = FakeNotifications();
    const allocator = NotificationIdAllocator();
    final scheduler = ReminderScheduler(
      notifications: notifications,
      allocator: allocator,
    );

    await scheduler.schedule(
      key: 'daily',
      title: 'Hari baru',
      body: 'Catat pengeluaran',
      when: DateTime.utc(2026, 11, 2, 9),
    );
    await scheduler.schedule(
      key: 'daily',
      title: 'Hari baru',
      body: 'Catat pengeluaran',
      when: DateTime.utc(2026, 11, 2, 10),
    );

    expect(notifications.cancelled, [allocator.idFor('daily')]);
    expect(notifications.scheduled, hasLength(2));
  });

  test('cancelling clears the key and its notification', () async {
    final notifications = FakeNotifications();
    const allocator = NotificationIdAllocator();
    final scheduler = ReminderScheduler(
      notifications: notifications,
      allocator: allocator,
    );
    await scheduler.schedule(
      key: 'daily',
      title: 'Hari baru',
      body: 'Catat pengeluaran',
      when: DateTime.utc(2026, 11, 2, 9),
    );

    await scheduler.cancel('daily');
    await scheduler.cancel('daily');
    await scheduler.cancelAll();

    expect(notifications.cancelled, [allocator.idFor('daily')]);
    expect(notifications.cancelAllCalls, 1);
    expect(scheduler.scheduledKeys, isEmpty);
  });
}
