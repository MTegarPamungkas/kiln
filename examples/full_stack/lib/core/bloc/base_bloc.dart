import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:kiln_core/kiln_core.dart';

/// Bloc base with the Kiln `Result` helpers.
///
/// `Bloc.emit` is marked test-only, so state always leaves a handler through
/// its [Emitter]; [reportResult] keeps that rule in one place.
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  /// Runs [action] and converts any thrown value into an [Err].
  Future<Result<R>> runGuarded<R>(FutureOr<R> Function() action) {
    return Result.guard<R>(action);
  }

  /// Emits [onFailure] through [emit] when [result] failed.
  ///
  /// A success usually needs no emit: when the domain also streams, the watched
  /// value already replaced the state.
  void reportResult<R>(
    Result<R> result,
    Emitter<State> emit,
    State Function(Failure failure) onFailure,
  ) {
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(onFailure(failure));
    }
  }
}
