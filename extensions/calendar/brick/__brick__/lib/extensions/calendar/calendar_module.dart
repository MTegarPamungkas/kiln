import 'package:kiln_core/kiln_core.dart';

import 'add_2_calendar_gateway.dart';
import 'calendar_gateway.dart';
import 'calendar_support.dart';
import 'device_calendar_service.dart';

/// Registers the native calendar writer.
final class CalendarModule extends KilnModule {
  const CalendarModule();

  @override
  String get id => 'calendar';

  @override
  Set<String> get provides => const <String>{'calendar'};

  @override
  Set<String> get platforms => const <String>{'android', 'ios'};

  @override
  void register(Registry registry) {
    const gateway = Add2CalendarGateway();
    registry
      ..registerSingleton<CalendarGateway>(gateway)
      ..registerSingleton<CalendarService>(
        DeviceCalendarService(gateway: gateway),
      )
      ..registerSingleton<CalendarSupport>(const CalendarSupport());
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<CalendarSupport>().info;
  }
}
