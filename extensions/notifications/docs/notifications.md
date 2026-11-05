# Notifications

`Notifications` displays, schedules, and cancels local notifications. The
contract lives in `kiln_core`; this extension provides the implementation.

```dart
final notifications = registry.read<Notifications>();

await notifications.requestPermission();
await notifications.show(
  const NotificationMessage(
    id: 1,
    title: 'Pesanan siap',
    body: 'Order #42 is ready for pickup',
    payload: '{"route":"/orders/42"}',
  ),
);
```

## Permission

`requestPermission()` uses the `Permissions` contract when the `permission`
extension is installed. If not, it calls the plugin directly. On iOS and macOS,
permission is not requested at start; call `requestPermission()` at the right
moment, for example after the user presses a reminder button.

## Tap

`taps` emits a `NotificationTap` for foreground taps, background action taps,
and the payload that launched the app. Read the payload with
`NotificationPayload.tryDecode(tap.payload)` and then pass its route to
navigation.

```dart
final subscription = notifications.taps.listen((tap) {
  final payload = NotificationPayload.tryDecode(tap.payload);
  if (payload?.route != null) {
    router.go(payload!.route!);
  }
});
```

## Channels

Android channels are defined in `NotificationChannels`. Add new channels there,
then show notifications with `channelId`. See
[android-channels.md](android-channels.md).

## Scheduling

Use `ReminderScheduler` so the same schedule is not created repeatedly on every
start. See [scheduling-and-timezones.md](scheduling-and-timezones.md).
