# calendar

Add events to the device calendar through the native calendar UI.

- `CalendarService.addEvent()` opens the system calendar insert screen.
- Supports title, description, location, start/end, all-day events, and an iOS
  reminder.
- Returns `false` when the native UI is unavailable.
- Available on Android and iOS.

```bash
kiln add calendar
```

## Runtime support

This extension reports readiness through `SupportRegistry`. The platform
declarations limit it to Android and iOS; other targets receive an
`unsupportedPlatform` report during bootstrap.

See [support and devices](../../docs/extensions/support-and-devices.md).
