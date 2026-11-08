import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/bloc/session_bloc.dart';

Future<void> _idle() => Future<void>.delayed(Duration.zero);

void main() {
  test('starts from the controller status', () async {
    final controller = SessionController(initialStatus: SessionStatus.unknown);
    final bloc = SessionBloc(controller);

    expect(bloc.state, SessionStatus.unknown);
    await bloc.close();
  });

  test('tracks every controller change', () async {
    final controller = SessionController();
    final bloc = SessionBloc(controller);
    final states = <SessionStatus>[];
    final subscription = bloc.stream.listen(states.add);

    controller.setSession(const AuthSession(userId: 'u1'));
    await _idle();
    controller.markUnauthenticated();
    await _idle();

    expect(bloc.state, SessionStatus.unauthenticated);
    expect(
      states,
      containsAll(<SessionStatus>[
        SessionStatus.authenticated,
        SessionStatus.unauthenticated,
      ]),
    );

    await subscription.cancel();
    await bloc.close();
  });

  test('sync republishes the current status', () async {
    final controller = SessionController(initialStatus: SessionStatus.unknown);
    final bloc = SessionBloc(controller);
    controller.setSession(const AuthSession(userId: 'u1'));
    await _idle();

    bloc.sync();
    await _idle();

    expect(bloc.state, SessionStatus.authenticated);
    await bloc.close();
  });

  test('closing cancels the controller subscription', () async {
    final controller = SessionController();
    final bloc = SessionBloc(controller);
    await bloc.close();

    controller.setSession(const AuthSession(userId: 'u2'));
    await _idle();

    expect(bloc.state, SessionStatus.unknown);
  });
}
