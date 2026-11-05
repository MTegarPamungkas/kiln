import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/calendar/calendar_gateway.dart';
import 'package:{{app_name}}/extensions/calendar/calendar_module.dart';
import 'package:{{app_name}}/extensions/calendar/calendar_support.dart';
import 'package:{{app_name}}/extensions/calendar/device_calendar_service.dart';

final class _FakeGateway implements CalendarGateway {
  bool result = true;
  CalendarEvent? lastEvent;

  @override
  Future<bool> add(CalendarEvent event) async {
    lastEvent = event;
    return result;
  }
}

void main() {
  test('delegates the event and returns the gateway result', () async {
    final gateway = _FakeGateway();
    final service = DeviceCalendarService(gateway: gateway);
    final event = CalendarEvent(
      title: 'Bali Weekend',
      startsAt: DateTime.utc(2026, 11, 5, 2),
      endsAt: DateTime.utc(2026, 11, 5, 4),
      location: 'Ubud',
    );

    expect(await service.addEvent(event), isTrue);
    expect(gateway.lastEvent, same(event));

    gateway.result = false;
    expect(await service.addEvent(event), isFalse);
  });

  test('module registers the calendar service and support', () {
    final registry = GetItRegistry();

    const CalendarModule().register(registry);

    expect(registry.read<CalendarService>(), isA<CalendarService>());
    expect(registry.read<CalendarGateway>(), isA<CalendarGateway>());
    expect(registry.read<CalendarSupport>(), isA<CalendarSupport>());
  });

  test('reports supported', () {
    expect(const CalendarSupport().info.isSupported, isTrue);
  });
}
