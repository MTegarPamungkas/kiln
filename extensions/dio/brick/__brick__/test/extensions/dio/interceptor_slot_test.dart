import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/dio/interceptors/interceptor_slot.dart';
import 'package:{{app_name}}/extensions/dio/interceptors/user_agent_interceptor.dart';

void main() {
  test('opens the http.interceptors slot with HttpMiddleware items', () {
    final registry = createTestRegistry();
    final slot = httpInterceptorSlot(registry);

    slot.add(const UserAgentInterceptor(), priority: 20, owner: 'test');

    expect(slot.name, SlotNames.httpInterceptors);
    expect(slot.items, hasLength(1));
    expect(slot.items.single, isA<HttpMiddleware>());
  });
}
