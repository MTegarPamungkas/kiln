import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/core/riverpod/provider_overrides.dart';
import 'package:{{app_name}}/core/riverpod/session_notifier.dart';

void main() {
  test('session notifier mirrors SessionController', () async {
    final registry = createTestRegistry();
    final container = testProviderContainer(registry);
    addTearDown(container.dispose);

    expect(container.read(sessionProvider), SessionStatus.unknown);

    registry.read<SessionController>().setSession(
      const AuthSession(userId: 'user-1'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionProvider), SessionStatus.authenticated);

    registry.read<SessionController>().markUnauthenticated();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionProvider), SessionStatus.unauthenticated);
  });
}
