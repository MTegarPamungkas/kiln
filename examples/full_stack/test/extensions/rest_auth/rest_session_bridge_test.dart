import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/rest_auth/rest_session_bridge.dart';

import 'test_support.dart';

void main() {
  test('mirrors sign in and sign out into SessionController', () async {
    final harness = AuthHarness();
    final controller = SessionController();
    final bridge = RestSessionBridge(auth: harness.auth, session: controller);

    await bridge.start();
    final session = await harness.auth.signIn(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(controller.isAuthenticated, isTrue);
    expect(controller.session?.userId, session.userId);

    await harness.auth.signOut();
    expect(controller.status, SessionStatus.unauthenticated);

    await bridge.dispose();
  });
}
