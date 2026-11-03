# Scheduling and timezones

`NotificationMessage` uses `DateTime`. When scheduled, the extension converts it
to `TZDateTime` using the device zone that `TimezoneResolver` reads from
`flutter_timezone`.

```dart
final scheduler = ReminderScheduler(notifications: notifications);

await scheduler.schedule(
  key: 'hydration',
  title: 'Minum air',
  body: 'Eight hours have passed since the last one',
  when: DateTime(2026, 11, 2, 20),
  channelId: 'kiln_default_reminders',
);
```

Guaranteed behavior:

- The same key with the same content and time is not rescheduled.
- The same key with a different time cancels the old schedule first.
- Each key gets a stable id from `NotificationIdAllocator`, so calling
  `schedule` on every start does not create duplicates.

The device time zone can change. Schedules that already exist keep using the
zone they were scheduled in; run `TimezoneResolver.configure()` again and
rebuild the reminders after a zone change if the app needs it.

On Android, scheduling depends on the receivers and the alarm mode. See
[troubleshooting-delivery.md](troubleshooting-delivery.md).
