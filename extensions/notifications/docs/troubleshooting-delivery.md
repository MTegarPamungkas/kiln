# Troubleshooting delivery

## Android receivers

`flutter_local_notifications` requires two receivers in
`android/app/src/main/AndroidManifest.xml`. The extension adds them automatically
through `android.receivers`; this section is only for verifying the install
result:

```xml
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON" />
    <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```

The extension also adds `POST_NOTIFICATIONS` and
`RECEIVE_BOOT_COMPLETED`.

## Exact alarms

With `exact_alarms: true`, the following permission is added to the manifest
automatically at install:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

On Android 12 and above the user must still grant **Alarms & reminders** access
to the app. If the permission is not granted, the plugin throws an error and
`DeviceNotifications` converts it into `Failure(notifications.unavailable)`.

## Scheduled notifications not appearing

1. Check the notification permission through `requestPermission()`.
2. Check the channel: the requested id must exist in `NotificationChannels`,
   otherwise the notification uses the default channel.
3. Check the device zone: `TimezoneResolver.configure()` must succeed.
4. Check Android's battery optimization; some vendors stop alarms.
5. Check the receivers above and make sure `RECEIVE_BOOT_COMPLETED` is present.

## Taps not registering

- Taps that open the app are read through `getNotificationAppLaunchDetails`, so
  call `initialize()` before listening to `taps`.
- Background action taps use `IsolateNameServer`; the web does not support them.
- Make sure the payload is smaller than `NotificationPayload.maxEncodedLength`.

## Web

Browsers only allow permission requests as a direct response to a user action.
Call `requestPermission()` from a button handler, not at start.
