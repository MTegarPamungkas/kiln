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
