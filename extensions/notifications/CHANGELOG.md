# Changelog

## 0.1.3

- Declare `SCHEDULE_EXACT_ALARM` through conditional native setup when the
  `exact_alarms` prompt is true, removing the manual manifest step.

## 0.1.2

- Declare `ScheduledNotificationReceiver` and
  `ScheduledNotificationBootReceiver` through `android.receivers`, so
  `zonedSchedule` notifications are actually delivered and survive reboots.
  The manual manifest step is no longer required.

## 0.1.1

- Configuration test now renders the prompt answers instead of hardcoded
  defaults, so regenerated apps keep passing `flutter test` with custom
  channel, icon, and exact-alarm settings.

## 0.1.0

- Initial notification gateway, channels, payload, tap hub, permission flow,
  timezone resolver, and reminder scheduler.
