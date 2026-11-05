import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('Failure', () {
    test('exposes code, message, kind, and retry flag', () {
      const failure = Failure(
        code: FailureCode.networkTimeout,
        message: 'Request timed out',
        kind: FailureKind.network,
        details: {'url': '/users'},
        isRetryable: true,
      );

      expect(failure.code, FailureCode.networkTimeout);
      expect(failure.message, 'Request timed out');
      expect(failure.kind, FailureKind.network);
      expect(failure.details['url'], '/users');
      expect(failure.isRetryable, isTrue);
      expect(failure.isCancelled, isFalse);
      expect(failure.isAuthFailure, isFalse);
      expect(failure.isPermissionFailure, isFalse);
    });

    test('classifies cancelled, auth, and permission failures', () {
      const cancelled = Failure(
        code: FailureCode.cancelled,
        message: 'Cancelled',
        kind: FailureKind.cancelled,
      );
      const auth = Failure(
        code: FailureCode.authInvalidCredentials,
        message: 'Wrong password',
        kind: FailureKind.authentication,
      );
      const permission = Failure(
        code: FailureCode.permissionPermanentlyDenied,
        message: 'Denied',
        kind: FailureKind.permission,
      );

      expect(cancelled.isCancelled, isTrue);
      expect(auth.isAuthFailure, isTrue);
      expect(permission.isPermissionFailure, isTrue);
    });

    test('Failure.from returns an existing Failure unchanged', () {
      const original = Failure(
        code: FailureCode.storageReadFailed,
        message: 'Cannot read',
        kind: FailureKind.storage,
      );

      expect(Failure.from(original), same(original));
    });

    test('Failure.from wraps an arbitrary error and keeps its stack', () {
      final stack = StackTrace.current;
      final wrapped = Failure.from(
        StateError('broken'),
        code: FailureCode.unexpected,
        stackTrace: stack,
      );

      expect(wrapped.code, FailureCode.unexpected);
      expect(wrapped.message, contains('broken'));
      expect(wrapped.cause, isA<StateError>());
      expect(wrapped.stackTrace, same(stack));
    });

    test('copyWith replaces only the provided fields', () {
      const original = Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Invalid',
        kind: FailureKind.validation,
      );

      final copy = original.copyWith(
        message: 'Still invalid',
        details: {'field': 'email'},
      );

      expect(copy.code, original.code);
      expect(copy.kind, original.kind);
      expect(copy.message, 'Still invalid');
      expect(copy.details['field'], 'email');
    });

    test('equality ignores cause and stack but includes identity fields', () {
      const a = Failure(
        code: FailureCode.networkOffline,
        message: 'Offline',
        kind: FailureKind.network,
        isRetryable: true,
      );
      const b = Failure(
        code: FailureCode.networkOffline,
        message: 'Offline',
        kind: FailureKind.network,
        isRetryable: true,
      );
      const c = Failure(
        code: FailureCode.networkOffline,
        message: 'Offline',
        kind: FailureKind.network,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('toString names the code and kind', () {
      const failure = Failure(
        code: FailureCode.authUnauthorized,
        message: 'No access',
        kind: FailureKind.authorization,
      );

      expect(
        failure.toString(),
        'Failure(auth.unauthorized, authorization): No access',
      );
    });
  });
}
