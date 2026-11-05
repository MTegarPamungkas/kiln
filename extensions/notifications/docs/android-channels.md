# Android channels

Android 8.0 and later group notifications into channels. Users can set the
sound and importance per channel, so a channel must be created once with a
stable id.

```dart
NotificationChannels(
  specs: <NotificationChannelSpec>[
    const NotificationChannelSpec(
      id: 'orders',
      name: 'Pesanan',
      description: 'Order status update',
      importance: NotificationImportance.high,
    ),
  ],
);
```

The rules:

- Do not change the id of a channel that has already been released; create a
  new channel instead.
- A channel's importance cannot be raised after it is created; the user holds
  the final say.
- Channel names and descriptions are visible in system settings, so write them
  in the user's language.

`flutter_local_notifications` creates a channel when a notification is first
displayed, but this extension also creates all channels at start so that empty
channels still appear in the app settings.
