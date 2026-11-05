import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

/// Matches an [Ok] result, optionally checking its value.
Matcher isOk<T>([Matcher? valueMatcher]) {
  final base = isA<Ok<T>>();
  if (valueMatcher == null) {
    return base;
  }
  return base.having((result) => result.value, 'value', valueMatcher);
}

/// Matches an [Err] result, optionally checking its failure.
Matcher isErr<T>([Matcher? failureMatcher]) {
  final base = isA<Err<T>>();
  if (failureMatcher == null) {
    return base;
  }
  return base.having((result) => result.failure, 'failure', failureMatcher);
}

/// Matches any [Failure], optionally with a specific code.
Matcher isFailure([FailureCode? code]) {
  final base = isA<Failure>();
  if (code == null) {
    return base;
  }
  return base.having((failure) => failure.code, 'code', code);
}

/// Matches a [Failure] or [Result] carrying [code].
Matcher hasCode(FailureCode code) {
  return anyOf(
    isFailure(code),
    isA<Err<Object?>>().having((result) => result.failure.code, 'code', code),
  );
}
