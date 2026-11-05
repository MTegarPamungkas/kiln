# Calendar

`calendar` provides `CalendarService` from `kiln_core`.

```dart
final calendar = registry.read<CalendarService>();

final added = await calendar.addEvent(
  CalendarEvent(
    title: 'Bali Weekend',
    description: 'Sunrise rice terraces',
    location: 'Ubud',
    startsAt: DateTime.now().add(const Duration(days: 1)),
    endsAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
  ),
);
```

The native insert screen lets the user choose the calendar and confirm the
event. A `false` result means the platform calendar UI could not be opened; it
is informational, not an app-startup failure.
