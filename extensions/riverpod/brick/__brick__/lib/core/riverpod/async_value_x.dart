import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';

extension AsyncValueX<T> on AsyncValue<T> {
  Failure? get failureOrNull {
    return switch (this) {
      AsyncError<T>(:final error, :final stackTrace) =>
        error is Failure
            ? error
            : Failure.from(error, stackTrace: stackTrace),
      _ => null,
    };
  }

  Future<Result<R>> guard<R>(FutureOr<R> Function() action) {
    return Result.guard<R>(action);
  }
}
