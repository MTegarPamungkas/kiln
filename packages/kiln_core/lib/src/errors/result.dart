import 'dart:async';

import 'failure.dart';
import 'failure_codes.dart';

/// A typed outcome that makes failure handling explicit in feature code.
///
/// Contracts throw [Failure]; [Result] is a convenience for features,
/// `runGuarded`, and `AsyncValue.guard`-style helpers.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  R fold<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) {
    return switch (this) {
      Ok<T>(:final value) => ok(value),
      Err<T>(:final failure) => err(failure),
    };
  }

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => fold<R>(ok: ok, err: err);

  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Ok<T>(:final value) => Ok<R>(transform(value)),
      Err<T>(:final failure) => Err<R>(failure),
    };
  }

  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Ok<T>(:final value) => transform(value),
      Err<T>(:final failure) => Err<R>(failure),
    };
  }

  T getOrElse(T Function(Failure failure) fallback) {
    return switch (this) {
      Ok<T>(:final value) => value,
      Err<T>(:final failure) => fallback(failure),
    };
  }

  T getOrThrow() {
    return switch (this) {
      Ok<T>(:final value) => value,
      Err<T>(:final failure) => throw failure,
    };
  }

  /// Runs [action] and converts any thrown value into [Err].
  static Future<Result<T>> guard<T>(
    FutureOr<T> Function() action, {
    FailureCode? code,
    String? message,
  }) async {
    try {
      return Ok<T>(await action());
    } on Failure catch (failure) {
      return Err<T>(failure);
    } catch (error, stackTrace) {
      return Err<T>(
        Failure.from(
          error,
          code: code,
          message: message,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Synchronous variant of [guard].
  static Result<T> capture<T>(
    T Function() action, {
    FailureCode? code,
    String? message,
  }) {
    try {
      return Ok<T>(action());
    } on Failure catch (failure) {
      return Err<T>(failure);
    } catch (error, stackTrace) {
      return Err<T>(
        Failure.from(
          error,
          code: code,
          message: message,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}
