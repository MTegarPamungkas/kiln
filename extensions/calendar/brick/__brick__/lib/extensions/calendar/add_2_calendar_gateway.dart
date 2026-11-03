import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:kiln_core/kiln_core.dart';

import 'calendar_gateway.dart';

/// [CalendarGateway] backed by add_2_calendar.
final class Add2CalendarGateway implements CalendarGateway {
  const Add2CalendarGateway();

  @override
  Future<bool> add(CalendarEvent event) async {
    try {
      return await Add2Calendar.addEvent2Cal(
        Event(
          title: event.title,
          description: event.description,
          location: event.location,
          startDate: event.startsAt,
          endDate: event.endsAt,
          allDay: event.allDay,
          iosParams: const IOSParams(reminder: Duration(minutes: 30)),
        ),
      );
    } on Object catch (error, stackTrace) {
      throw Failure.from(
        error,
        code: FailureCode.unavailable,
        kind: FailureKind.unavailable,
        stackTrace: stackTrace,
      );
    }
  }
}
