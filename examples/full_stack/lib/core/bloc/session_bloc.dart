import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/core/bloc/base_bloc.dart';

/// Events understood by [SessionBloc].
sealed class SessionEvent {
  const SessionEvent();
}

/// The wrapped [SessionController] reported a new status.
final class SessionStatusChanged extends SessionEvent {
  const SessionStatusChanged(this.status);

  final SessionStatus status;
}

/// Republishes the status the controller holds right now.
final class SessionSynced extends SessionEvent {
  const SessionSynced();
}

/// Mirrors [SessionController] into a Bloc for the widget tree.
final class SessionBloc extends BaseBloc<SessionEvent, SessionStatus> {
  SessionBloc(this._controller) : super(_controller.status) {
    on<SessionStatusChanged>((event, emit) => emit(event.status));
    on<SessionSynced>((event, emit) => emit(_controller.status));
    _subscription = _controller.changes.listen(
      (status) => add(SessionStatusChanged(status)),
    );
  }

  final SessionController _controller;
  late final StreamSubscription<SessionStatus> _subscription;

  /// Emits the status held by the controller right now.
  void sync() => add(const SessionSynced());

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
