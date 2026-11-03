import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/bloc/session_cubit.dart';

void main() {
  test('session cubit mirrors SessionController', () async {
    final controller = SessionController();
    final cubit = SessionCubit(controller);

    expect(cubit.state, SessionStatus.unknown);

    controller.setSession(const AuthSession(userId: 'user-1'));

    expect(cubit.state, SessionStatus.authenticated);

    controller.markUnauthenticated();
    expect(cubit.state, SessionStatus.unauthenticated);

    await cubit.close();
    await controller.dispose();
  });
}
