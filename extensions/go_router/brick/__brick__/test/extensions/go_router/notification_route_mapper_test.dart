import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/go_router/notification_route_mapper.dart';

void main() {
  const mapper = NotificationRouteMapper();

  test('push routes stay local and retain query parameters', () {
    expect(
      mapper.mapPayload('{"route":"/orders/42?tab=items#summary"}'),
      '/orders/42?tab=items#summary',
    );
    for (final route in [
      '//other.test/orders',
      '/\\other.test',
      '/%2fother.test',
      '/%252fother.test',
      '/orders/%2e%2e/admin',
      '/orders/%0a',
    ]) {
      expect(mapper.mapPayload(route), isNull, reason: route);
    }
  });

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
