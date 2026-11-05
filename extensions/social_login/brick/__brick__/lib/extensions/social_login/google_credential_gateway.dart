import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kiln_core/kiln_core.dart';

/// Google credential access that can be faked in tests.
abstract interface class GoogleCredentialGateway {
  Future<SocialCredential?> signIn({String? clientId, String? serverClientId});

  Future<void> signOut();
}

/// Gateway backed by google_sign_in.
final class SdkGoogleCredentialGateway implements GoogleCredentialGateway {
  SdkGoogleCredentialGateway();

  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _initialize({String? clientId, String? serverClientId}) async {
    if (_initialized) {
      return;
    }
    await _google.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _initialized = true;
  }

  @override
  Future<SocialCredential?> signIn({
    String? clientId,
    String? serverClientId,
  }) async {
    try {
      await _initialize(clientId: clientId, serverClientId: serverClientId);
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const Failure(
          code: FailureCode.authProviderDisabled,
          message: 'Google did not return an id token.',
          kind: FailureKind.authentication,
        );
      }
      return SocialCredential(
        provider: SocialProvider.google,
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (error) {
      throw mapGoogleException(error);
    }
  }

  @override
  Future<void> signOut() => _google.signOut();
}

/// Converts a google_sign_in exception into a platform exception.
Object mapGoogleException(GoogleSignInException error) {
  return PlatformException(code: error.code.name, message: error.description);
}
