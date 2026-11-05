import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:with_supabase/extensions/supabase/supabase_failure_mapper.dart';

void main() {
  test('AuthException kredensial salah menjadi auth.invalid_credentials', () {
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
  });

  test('AuthException email belum dikonfirmasi terdeteksi', () {
    final failure = mapSupabaseError(
      const AuthException('Email not confirmed', code: 'email_not_confirmed'),
    );

    expect(failure.code, FailureCode.authEmailNotVerified);
  });

  test('AuthException sesi hilang menjadi auth.session_expired', () {
    final failure = mapSupabaseError(
      const AuthException('Auth session missing!'),
    );

    expect(failure.code, FailureCode.authSessionExpired);
    expect(failure.kind, FailureKind.session);
  });

  test('AuthException rate limit bisa dicoba ulang', () {
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

  test('PostgrestException tanpa baris menjadi remote_database.not_found', () {
    final failure = mapSupabaseError(
      const PostgrestException(
        message: 'JSON object requested, multiple (or no) rows returned',
        code: 'PGRST116',
      ),
    );

    expect(failure.code, FailureCode.remoteDatabaseNotFound);
    expect(failure.kind, FailureKind.database);
  });

  test('PostgrestException unique violation menjadi konflik', () {
    final failure = mapSupabaseError(
      const PostgrestException(message: 'duplicate key', code: '23505'),
    );

    expect(failure.code, FailureCode.remoteDatabaseConflict);
  });

  test('PostgrestException RLS menjadi kegagalan otorisasi', () {
    final failure = mapSupabaseError(
      const PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      ),
    );

    expect(failure.kind, FailureKind.authorization);
    expect(failure.code, FailureCode.remoteDatabaseQueryFailed);
  });

  test('StorageException 404 menjadi file.not_found walau operasi unggah', () {
    final failure = mapSupabaseError(
      const StorageException('Object not found', statusCode: '404'),
      fallbackCode: FailureCode.fileUploadFailed,
    );

    expect(failure.code, FailureCode.fileNotFound);
    expect(failure.kind, FailureKind.storage);
  });

  test('StorageException lain memakai kode fallback pemanggil', () {
    final failure = mapSupabaseError(
      const StorageException('Internal error', statusCode: '500'),
      fallbackCode: FailureCode.fileUploadFailed,
    );

    expect(failure.code, FailureCode.fileUploadFailed);
    expect(failure.details['status_code'], '500');
  });

  test('TimeoutException menjadi network.timeout yang bisa dicoba ulang', () {
    final failure = mapSupabaseError(
      TimeoutException('slow', const Duration(seconds: 1)),
    );

    expect(failure.code, FailureCode.networkTimeout);
    expect(failure.kind, FailureKind.network);
    expect(failure.isRetryable, isTrue);
  });

  test('error jaringan teks dikenali sebagai network', () {
    final failure = mapSupabaseError(
      Exception('SocketException: Failed host lookup: demo.supabase.co'),
      fallbackCode: FailureCode.remoteDatabaseUnavailable,
    );

    expect(failure.code, FailureCode.networkUnreachable);
    expect(failure.kind, FailureKind.network);
  });

  test('Failure yang sudah ada diteruskan apa adanya', () {
    const original = Failure(
      code: FailureCode.fileNotFound,
      message: 'hilang',
      kind: FailureKind.storage,
    );

    expect(mapSupabaseError(original), same(original));
  });

  test('error tak dikenal memakai kode dan kind fallback', () {
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
