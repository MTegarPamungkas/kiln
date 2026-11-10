import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// A domain action that takes one input and returns a typed outcome.
///
/// Features declare one class per action under
/// `lib/features/<feature>/domain/usecases/`. Handling the [Result] here keeps
/// the presentation layer free of try/catch.
abstract interface class UseCase<Params, Value> {
  Future<Result<Value>> call(Params params);
}

/// A domain action that needs no input.
abstract interface class NoParamsUseCase<Value> {
  Future<Result<Value>> call();
}

/// A domain action that observes a changing source instead of completing.
///
/// A stream is the return type, so a failure travels as a [Failure] event and
/// the presentation layer keeps one error path for loads and mutations.
abstract interface class StreamUseCase<Value> {
  Stream<Value> call();
}
