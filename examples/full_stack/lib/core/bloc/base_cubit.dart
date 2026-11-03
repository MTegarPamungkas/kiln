import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:kiln_core/kiln_core.dart';

/// Cubit with a closed guard and a `Failure`-aware guarded runner.
abstract class BaseCubit<T> extends Cubit<T> {
  BaseCubit(super.initialState);

  void safeEmit(T state) {
    if (!isClosed) {
      emit(state);
    }
  }

  Future<Result<R>> runGuarded<R>(FutureOr<R> Function() action) {
    return Result.guard<R>(action);
  }
}
