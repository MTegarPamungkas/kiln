import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_supabase/extensions/supabase/supabase_auth_repository.dart';
import 'package:with_supabase/extensions/supabase/supabase_gateway.dart';
import 'package:with_supabase/extensions/supabase/supabase_session_bridge.dart';

import 'test_support.dart';

void main() {
  late FakeSupabaseGateway gateway;
  late SupabaseAuthRepository auth;
  late SessionController controller;
  late SupabaseSessionBridge bridge;

  setUp(() {
    gateway = FakeSupabaseGateway();
    auth = SupabaseAuthRepository(gateway: gateway);
    controller = SessionController();
    bridge = SupabaseSessionBridge(auth: auth, controller: controller);
  });

  tearDown(() async {
    await bridge.dispose();
    await auth.dispose();
    await controller.dispose();
  });

  test('start fills SessionController from the repository session', () async {
    gateway.initialSession = const SupabaseSession(
      userId: 'user-9',
      email: 'stored@kiln.dev',
      accessToken: 'stored-token',
    );
    await auth.restore();

    bridge.start();

    expect(bridge.isAttached, isTrue);
    expect(controller.status, SessionStatus.authenticated);
    expect(controller.session?.userId, 'user-9');
    expect(controller.session?.email, 'stored@kiln.dev');
  });

  test('start without a session marks unauthenticated', () {
    bridge.start();

    expect(controller.status, SessionStatus.unauthenticated);
    expect(controller.session, isNull);
  });

  test('session changes are forwarded to SessionController', () async {
    bridge.start();
    final statuses = <SessionStatus>[];
    final subscription = controller.changes.listen(statuses.add);

    await auth.signIn(email: 'user@kiln.dev', password: 'password123');

    expect(statuses.last, SessionStatus.authenticated);
    expect(controller.session?.displayName, 'Demo User');

    await auth.signOut();

    expect(statuses.last, SessionStatus.unauthenticated);
    expect(controller.session, isNull);

    await subscription.cancel();
  });

  test('dispose stops forwarding changes', () async {
    bridge.start();
    await bridge.dispose();

    await auth.signIn(email: 'user@kiln.dev', password: 'password123');

    expect(bridge.isAttached, isFalse);
    expect(controller.session, isNull);
  });
}
