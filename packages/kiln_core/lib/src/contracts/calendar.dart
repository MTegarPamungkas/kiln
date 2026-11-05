/// One event written to the device calendar.
final class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.description,
    this.location,
    this.allDay = false,
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? description;
  final String? location;
  final bool allDay;
}

/// Writes events to the device calendar UI.
abstract interface class CalendarService {
  /// Returns false when the platform calendar UI is unavailable.
  Future<bool> addEvent(CalendarEvent event);
}
