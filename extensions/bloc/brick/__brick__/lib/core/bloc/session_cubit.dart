import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/bloc/base_cubit.dart';

/// Mirrors [SessionController] into a Cubit for the widget tree.
final class SessionCubit extends BaseCubit<SessionStatus> {
  SessionCubit(this._controller) : super(_controller.status) {
    _subscription = _controller.changes.listen(safeEmit);
  }

  final SessionController _controller;
  late final StreamSubscription<SessionStatus> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
