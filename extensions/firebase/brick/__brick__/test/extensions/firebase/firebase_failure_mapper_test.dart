import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firebase_failure_mapper.dart';

void main() {
  group('mapFirebaseError', () {
    test('keeps an existing Failure untouched', () {
      const failure = Failure(
        code: FailureCode.authCancelled,
        message: 'Cancelled',
        kind: FailureKind.cancelled,
      );

      expect(mapFirebaseError(failure), same(failure));
    });

    test('maps invalid auth credentials', () {
      final failure = mapFirebaseError(
        FirebaseException(plugin: 'firebase_auth', code: 'wrong-password'),
      );

      expect(failure.kind, FailureKind.authentication);
      expect(failure.code, FailureCode.authInvalidCredentials);
    });

    test('maps user-not-found to invalid credentials', () {
      final failure = mapFirebaseError(
        FirebaseException(plugin: 'firebase_auth', code: 'user-not-found'),
      );

      expect(failure.code, FailureCode.authInvalidCredentials);
    });

    test('maps an unverified email', () {
      final failure = mapFirebaseError(
        FirebaseException(plugin: 'firebase_auth', code: 'email-not-verified'),
      );

      expect(failure.code, FailureCode.authEmailNotVerified);
    });

    test('marks too-many-requests as retryable', () {
      final failure = mapFirebaseError(
        FirebaseException(plugin: 'firebase_auth', code: 'too-many-requests'),
      );

      expect(failure.isRetryable, isTrue);
      expect(failure.code, FailureCode.unavailable);
    });

    test('maps permission-denied to authUnauthorized', () {
      final failure = mapFirebaseError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );

      expect(failure.kind, FailureKind.authorization);
      expect(failure.code, FailureCode.authUnauthorized);
    });

    test('maps Firestore not-found', () {
      final failure = mapFirebaseError(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      );

      expect(failure.kind, FailureKind.database);
      expect(failure.code, FailureCode.remoteDatabaseNotFound);
    });

    test('maps Storage object-not-found to fileNotFound', () {
      final failure = mapFirebaseError(
        FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'),
      );

      expect(failure.kind, FailureKind.file);
      expect(failure.code, FailureCode.fileNotFound);
    });

    test('maps network errors to network codes', () {
      final failure = mapFirebaseError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      expect(failure.kind, FailureKind.network);
      expect(failure.code, FailureCode.remoteDatabaseUnavailable);
      expect(failure.isRetryable, isTrue);
    });

    test('maps timeouts to networkTimeout', () {
      final failure = mapFirebaseError(TimeoutException('slow'));

      expect(failure.code, FailureCode.networkTimeout);
      expect(failure.kind, FailureKind.network);
      expect(failure.isRetryable, isTrue);
    });

    test('unknown errors become unexpected failures', () {
      final failure = mapFirebaseError(StateError('boom'));

      expect(failure.code, FailureCode.unexpected);
      expect(failure.cause, isA<StateError>());
    });
  });
}
