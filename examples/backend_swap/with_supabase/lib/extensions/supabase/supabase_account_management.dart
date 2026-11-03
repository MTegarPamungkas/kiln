// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

import 'supabase_failure_mapper.dart';
import 'supabase_gateway.dart';

/// [AccountManagement] implementation on top of Supabase Auth.
///
/// Every call uses the active session; when there is none Supabase returns an
/// error and the mapper turns it into `Failure(auth.session_expired)`.
final class SupabaseAccountManagement implements AccountManagement {
  SupabaseAccountManagement({
    required SupabaseGateway gateway,
    Uri? redirectUri,
  }) : _gateway = gateway,
       redirectUri = redirectUri;

  final SupabaseGateway _gateway;

  /// Callback URL used for password reset and email verification.
  final Uri? redirectUri;

  @override
  bool get isEmailVerified => _gateway.isEmailVerified;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final value = email.trim();
    if (!_looksLikeEmail(value)) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Alamat email tidak valid.',
        kind: FailureKind.validation,
      );
    }
    await _call(
      () => _gateway.sendPasswordResetEmail(
        value,
        redirectTo: redirectUri?.toString(),
      ),
    );
  }

  @override
  Future<void> sendEmailVerification() {
    return _call(
      () => _gateway.sendEmailVerification(redirectTo: redirectUri?.toString()),
    );
  }

  @override
  Future<void> reloadUser() => _call(_gateway.refreshUser);

  @override
  Future<void> updateDisplayName(String displayName) async {
    final value = displayName.trim();
    if (value.isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Nama tampilan tidak boleh kosong.',
        kind: FailureKind.validation,
      );
    }
    await _call(
      () => _gateway.updateUser(data: <String, Object?>{'display_name': value}),
    );
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) async {
    final value = photoUrl?.trim();
    if (value != null && value.isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'URL foto tidak boleh berupa teks kosong; pakai null untuk menghapus.',
        kind: FailureKind.validation,
      );
    }
    await _call(
      () => _gateway.updateUser(
        data: <String, Object?>{'avatar_url': value},
      ),
    );
  }

  bool _looksLikeEmail(String value) {
    final at = value.indexOf('@');
    return at > 0 && at < value.length - 1 && !value.contains(' ');
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.authUnauthorized,
        fallbackKind: FailureKind.authentication,
      );
    }
  }
}
