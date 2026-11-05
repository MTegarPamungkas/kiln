import 'package:kiln_core/kiln_core.dart';

/// Gate verbs for the native social credential service.
///
/// `gate.socialSignIn` uses the installed `SocialAuth` backend (for example
/// Supabase OAuth in the browser). This exposes the `SocialLogin` service that
/// obtains a credential directly from the Google or Apple SDK on the device, so
/// the app can drive native sign-in and hand the credential to any backend. The
/// SDK returns a `Result`; the app renders the provider buttons itself.
extension GateSocialLoginX on Gate {
  SocialLogin get socialLogin => use<SocialLogin>();

  /// Obtains a native credential from [provider]; `Ok(null)` means cancelled.
  Future<Result<SocialCredential?>> socialLoginSignIn(
    SocialProvider provider,
  ) => call(() => socialLogin.signIn(provider));

  /// Signs the native provider session out.
  Future<Result<void>> socialLoginSignOut() => call<void>(socialLogin.signOut);
}
