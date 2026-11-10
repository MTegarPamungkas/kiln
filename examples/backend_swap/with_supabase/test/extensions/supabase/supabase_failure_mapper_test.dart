import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:with_supabase/extensions/supabase/supabase_failure_mapper.dart';

void main() {
  test(
    'a wrong-credentials AuthException becomes auth.invalid_credentials',
    () {
      final failure = mapSupabaseError(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );

      expect(failure.code, FailureCode.authInvalidCredentials);
      expect(failure.kind, FailureKind.authentication);
      expect(failure.details['supabase_code'], 'invalid_credentials');
      expect(failure.isRetryable, isFalse);
    },
  );

  test('an unconfirmed-email AuthException is detected', () {
    final failure = mapSupabaseError(
      const AuthException('Email not confirmed', code: 'email_not_confirmed'),
    );

    expect(failure.code, FailureCode.authEmailNotVerified);
  });

  test('a lost AuthException session becomes auth.session_expired', () {
    final failure = mapSupabaseError(
      const AuthException('Auth session missing!'),
    );

    expect(failure.code, FailureCode.authSessionExpired);
    expect(failure.kind, FailureKind.session);
  });

  test('a rate-limit AuthException is retryable', () {
    final failure = mapSupabaseError(
      const AuthException(
        'Request rate limit reached',
        statusCode: '429',
        code: 'over_request_rate_limit',
      ),
    );

    expect(failure.code, FailureCode.unavailable);
    expect(failure.isRetryable, isTrue);
  });

  test('a no-rows PostgrestException becomes remote_database.not_found', () {
    final failure = mapSupabaseError(
      const PostgrestException(
        message: 'JSON object requested, multiple (or no) rows returned',
        code: 'PGRST116',
      ),
    );

    expect(failure.code, FailureCode.remoteDatabaseNotFound);
    expect(failure.kind, FailureKind.database);
  });

  test('a unique-violation PostgrestException becomes a conflict', () {
    final failure = mapSupabaseError(
      const PostgrestException(message: 'duplicate key', code: '23505'),
    );

    expect(failure.code, FailureCode.remoteDatabaseConflict);
  });

  test('an RLS PostgrestException becomes an authorization failure', () {
    final failure = mapSupabaseError(
      const PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      ),
    );

    expect(failure.kind, FailureKind.authorization);
    expect(failure.code, FailureCode.remoteDatabaseQueryFailed);
  });

  test('a 404 StorageException becomes file.not_found even on upload', () {
    final failure = mapSupabaseError(
      const StorageException('Object not found', statusCode: '404'),
      fallbackCode: FailureCode.fileUploadFailed,
    );

    expect(failure.code, FailureCode.fileNotFound);
    expect(failure.kind, FailureKind.storage);
  });

  test('other StorageExceptions use the caller fallback code', () {
    final failure = mapSupabaseError(
      const StorageException('Internal error', statusCode: '500'),
      fallbackCode: FailureCode.fileUploadFailed,
    );

    expect(failure.code, FailureCode.fileUploadFailed);
    expect(failure.details['status_code'], '500');
  });

  test('a TimeoutException becomes a retryable network.timeout', () {
    final failure = mapSupabaseError(
      TimeoutException('slow', const Duration(seconds: 1)),
    );

    expect(failure.code, FailureCode.networkTimeout);
    expect(failure.kind, FailureKind.network);
    expect(failure.isRetryable, isTrue);
  });

  test('a network text error is recognized as network', () {
    final failure = mapSupabaseError(
      Exception('SocketException: Failed host lookup: demo.supabase.co'),
      fallbackCode: FailureCode.remoteDatabaseUnavailable,
    );

    expect(failure.code, FailureCode.networkUnreachable);
    expect(failure.kind, FailureKind.network);
  });

  test('an existing Failure passes through as-is', () {
    const original = Failure(
      code: FailureCode.fileNotFound,
      message: 'hilang',
      kind: FailureKind.storage,
    );

    expect(mapSupabaseError(original), same(original));
  });

  test('an unknown error uses the fallback code and kind', () {
    final failure = mapSupabaseError(
      StateError('aneh'),
      fallbackCode: FailureCode.remoteDatabaseQueryFailed,
      fallbackKind: FailureKind.database,
    );

    expect(failure.code, FailureCode.remoteDatabaseQueryFailed);
    expect(failure.kind, FailureKind.database);
    expect(failure.cause, isA<StateError>());
  });
}
