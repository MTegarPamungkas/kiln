import 'package:kiln_core/kiln_core.dart';

import 'calendar_gateway.dart';

/// [CalendarService] backed by a CalendarGateway.
final class DeviceCalendarService implements CalendarService {
  const DeviceCalendarService({required this.gateway});

  final CalendarGateway gateway;

  @override
  Future<bool> addEvent(CalendarEvent event) => gateway.add(event);
}
