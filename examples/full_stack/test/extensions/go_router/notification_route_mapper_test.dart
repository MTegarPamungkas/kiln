import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/go_router/notification_route_mapper.dart';

void main() {
  const mapper = NotificationRouteMapper();

  test('accepts a plain route payload', () {
    expect(mapper.map(const NotificationTap('/orders/42')), '/orders/42');
    expect(mapper.mapPayload('  /explore  '), '/explore');
  });

  test('reads a route from a JSON payload', () {
    expect(mapper.mapPayload('{"route":"/orders/42","id":42}'), '/orders/42');
  });

  test('ignores empty, malformed, and non-route payloads', () {
    expect(mapper.mapPayload(null), isNull);
    expect(mapper.mapPayload('   '), isNull);
    expect(mapper.mapPayload('orders/42'), isNull);
    expect(mapper.mapPayload('{"route":42}'), isNull);
    expect(mapper.mapPayload('{"other":"/orders"}'), isNull);
    expect(mapper.mapPayload('{not json}'), isNull);
    expect(mapper.map(const NotificationTap(null)), isNull);
  });
}
