# Event flow

`CalendarService.addEvent` opens the platform insert screen. It does not write
silently, so the user can choose the calendar and confirm or cancel the event.

## Build the event

```dart
final start = DateTime.now().add(const Duration(days: 1));
final event = CalendarEvent(
  title: 'Bali Weekend',
  description: 'Sunrise rice terraces',
  location: 'Ubud',
  startsAt: start,
  endsAt: start.add(const Duration(hours: 2)),
  allDay: false,
);
```

- Use local `DateTime` values. The native screen applies the device timezone.
- Pass a sensible `startsAt`/`endsAt` range; the contract does not reorder or
  validate it, so an inverted range reaches the native screen.
- For an all-day event, pass a date-only range and set `allDay: true`.
- The contract has no recurrence field; recurring events must be created by the
  platform UI or a backend-specific integration.

## Handle the outcome

```dart
final added = await gate.addCalendarEvent(event);
added.fold(
  ok: (created) => created
      ? showSnack('Event opened in the calendar')
      : showSnack('No calendar app is available'),
  err: (failure) => showFailure(failure),
);
```

`Ok(false)` means the native calendar UI could not be opened; it is an
informational outcome, not an app-startup failure. A `Failure` means validation,
permission, or platform integration failed.

## Platform notes

- Android and iOS only. The manifest declares both; other platforms receive
  `unsupportedPlatform` from `SupportRegistry`, and the contract is not
  registered there.
- The extension does not read the user's calendars and does not request broad
  calendar access. The native insert screen owns the permission prompt when the
  platform needs one.
- A user can still cancel or edit the event inside the native screen. The
  returned boolean only says the screen was opened, not that the event was
  saved.

## Testing

There is no shared `CalendarService` contract suite in `kiln_testing`.
Test the app against a fake `CalendarService` that returns true/false and throws
the validation/permission failures you expect, and keep the native screen for
manual device testing.
