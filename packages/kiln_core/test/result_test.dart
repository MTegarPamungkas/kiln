import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  const failure = Failure(
    code: FailureCode.networkTimeout,
    message: 'Request timed out',
    kind: FailureKind.network,
  );

  group('Result', () {
    test('Ok exposes its value and folds to the ok branch', () {
      const result = Ok<int>(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(result.fold(ok: (value) => value * 2, err: (_) => -1), 84);
      expect(result.when(ok: (value) => value + 1, err: (_) => 0), 43);
    });

    test('Err carries a Failure and folds to the err branch', () {
      const result = Err<int>(failure);

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
      expect(
        result.fold(ok: (_) => 0, err: (value) => value.code),
        failure.code,
      );
    });

    test('map and flatMap transform only Ok values', () {
      const ok = Ok<int>(21);
      const err = Err<int>(failure);

      expect(ok.map((value) => value * 2), const Ok<int>(42));
      expect(err.map((value) => value * 2), isA<Err<int>>());
      expect(err.map((value) => value * 2).failureOrNull, failure);

      expect(
        ok.flatMap((value) => Ok<String>('$value')),
        const Ok<String>('21'),
      );
      expect(err.flatMap((value) => Ok<String>('$value')), isA<Err<String>>());
    });

    test('getOrElse and getOrThrow behave by variant', () {
      const ok = Ok<int>(7);
      const err = Err<int>(failure);

      expect(ok.getOrElse((_) => 0), 7);
      expect(err.getOrElse((value) => value.code.value.length), 15);
      expect(ok.getOrThrow(), 7);
      expect(() => err.getOrThrow(), throwsA(same(failure)));
    });

    test('guard converts a thrown Failure without wrapping it', () async {
      final result = await Result.guard<int>(() async => throw failure);

      expect(result.failureOrNull, same(failure));
    });

    test('guard wraps unexpected errors with the requested code', () async {
      final result = await Result.guard<int>(
        () => throw StateError('boom'),
        code: FailureCode.configurationInvalid,
        message: 'Bad configuration',
      );

      expect(result.failureOrNull?.code, FailureCode.configurationInvalid);
      expect(result.failureOrNull?.message, 'Bad configuration');
      expect(result.failureOrNull?.cause, isA<StateError>());
    });

    test('capture works synchronously', () {
      expect(Result.capture(() => 3), const Ok<int>(3));

      final result = Result.capture<int>(() => throw ArgumentError('bad'));
      expect(result.failureOrNull?.cause, isA<ArgumentError>());
    });

    test('Ok and Err compare by value', () {
      expect(const Ok<int>(1), const Ok<int>(1));
      expect(const Err<int>(failure), const Err<int>(failure));
      expect(const Ok<int>(1), isNot(const Ok<int>(2)));
      expect(const Ok<int>(1).hashCode, const Ok<int>(1).hashCode);
    });
  });
}
