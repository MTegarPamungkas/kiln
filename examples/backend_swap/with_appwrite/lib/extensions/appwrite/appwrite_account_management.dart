import 'package:kiln_core/kiln_core.dart';

import 'appwrite_account.dart';
import 'appwrite_failure_mapper.dart';

/// [AccountManagement] on top of the Appwrite `Account` service.
///
/// Appwrite has no profile photo field, so [updatePhotoUrl] stores the URL in
/// the user preferences under `photoUrl`.
final class AppwriteAccountManagement implements AccountManagement {
  AppwriteAccountManagement({
    required this.account,
    this.recoveryRedirectUrl = defaultRecoveryRedirectUrl,
    this.verificationRedirectUrl = defaultVerificationRedirectUrl,
    bool emailVerified = false,
    AppwriteFailureMapper failureMapper = const AppwriteFailureMapper(),
  }) : isEmailVerified = emailVerified,
       _failures = failureMapper;

  static const String defaultRecoveryRedirectUrl = 'kiln://auth/recovery';
  static const String defaultVerificationRedirectUrl = 'kiln://auth/verify';

  final AppwriteAccount account;

  /// Redirect URL registered in the Appwrite console for password resets.
  final String recoveryRedirectUrl;

  /// Redirect URL registered in the Appwrite console for email verification.
  final String verificationRedirectUrl;

  final AppwriteFailureMapper _failures;
  @override
  bool isEmailVerified;
  String? _displayName;
  String? _photoUrl;

  /// Last display name read by [reloadUser] or written by [updateDisplayName].
  String? get displayName => _displayName;

  /// Last photo URL read by [reloadUser] or written by [updatePhotoUrl].
  String? get photoUrl => _photoUrl;

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _guard(() async {
      if (email.trim().isEmpty) {
        throw _invalid('An email address is required.');
      }
      await account.sendPasswordResetEmail(
        email,
        redirectUrl: recoveryRedirectUrl,
      );
    });
  }

  @override
  Future<void> sendEmailVerification() {
    return _guard(
      () => account.sendEmailVerification(redirectUrl: verificationRedirectUrl),
    );
  }

  @override
  Future<void> reloadUser() {
    return _guard(() async {
      final user = await account.currentUser();
      if (user == null) {
        throw const Failure(
          code: FailureCode.authSessionExpired,
          message: 'The Appwrite session has expired.',
          kind: FailureKind.authentication,
        );
      }
      isEmailVerified = user.emailVerified;
      _displayName = user.displayName;
      _photoUrl = user.photoUrl;
    });
  }

  @override
  Future<void> updateDisplayName(String displayName) {
    return _guard(() async {
      final trimmed = displayName.trim();
      if (trimmed.isEmpty) {
        throw _invalid('A display name is required.');
      }
      await account.updateDisplayName(trimmed);
      _displayName = trimmed;
    });
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) {
    return _guard(() async {
      final normalized = photoUrl?.trim();
      if (normalized != null && normalized.isEmpty) {
        throw _invalid('The photo URL must not be empty.');
      }
      await account.updatePhotoUrl(normalized);
      _photoUrl = normalized;
    });
  }

  Failure _invalid(String message) {
    return Failure(
      code: FailureCode.validationInvalidInput,
      message: message,
      kind: FailureKind.validation,
    );
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on Object catch (error, stackTrace) {
      throw _failures.map(
        error,
        scope: AppwriteFailureScope.account,
        stackTrace: stackTrace,
      );
    }
  }
}
