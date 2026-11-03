/// Sends a password reset message to [email].
abstract interface class PasswordRecovery {
  Future<void> sendPasswordResetEmail(String email);
}

/// Controls the signed-in user's email verification state.
abstract interface class EmailVerification {
  bool get isEmailVerified;

  Future<void> sendEmailVerification();

  Future<void> reloadUser();
}

/// Updates the signed-in user's profile fields.
abstract interface class ProfileUpdate {
  Future<void> updateDisplayName(String displayName);

  Future<void> updatePhotoUrl(String? photoUrl);
}

/// Optional account operations that sit beside [AuthRepository].
abstract interface class AccountManagement
    implements PasswordRecovery, EmailVerification, ProfileUpdate {}
