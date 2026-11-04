# notifications

An implementation of `Notifications` from `kiln_core` on top of
`flutter_local_notifications`.

- The Android channel is created at start; its id and small icon come from the
  prompt.
- Notification permission is requested through the `Permissions` contract when
  it is installed, then falls back to the plugin when the contract is not
  available.
- `NotificationPayload` carries the route and typed arguments as JSON with a
  size limit.
- `NotificationTapHub` merges foreground taps, background taps, and the payload
  that launched the app.
- `ReminderScheduler` reschedules reminders idempotently per key.
- `TimezoneResolver` uses the device time zone, not UTC.

After install, the Android receivers for scheduling have already been added
automatically through `android.receivers`. If `exact_alarms` is selected,
complete the exact alarm permission step in
[docs/troubleshooting-delivery.md](docs/troubleshooting-delivery.md).

## Gate

```dart
final granted = await gate.requestNotificationPermission(); // Result<bool>
await gate.showNotification(NotificationMessage(id: 1, title: 'Hi', body: 'New'));
await gate.scheduleNotification(message, when);
await gate.cancelNotification(1);
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
