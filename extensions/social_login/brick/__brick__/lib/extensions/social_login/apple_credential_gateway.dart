import 'package:flutter/services.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple credential access that can be faked in tests.
abstract interface class AppleCredentialGateway {
  Future<SocialCredential?> signIn({
    required String nonce,
    required String nonceSha256,
    String? serviceId,
    String? redirectUri,
  });
}

/// Gateway backed by sign_in_with_apple.
final class SdkAppleCredentialGateway implements AppleCredentialGateway {
  const SdkAppleCredentialGateway();

  @override
  Future<SocialCredential?> signIn({
    required String nonce,
    required String nonceSha256,
    String? serviceId,
    String? redirectUri,
  }) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonceSha256,
        webAuthenticationOptions: serviceId == null || redirectUri == null
            ? null
            : WebAuthenticationOptions(
                clientId: serviceId,
                redirectUri: Uri.parse(redirectUri),
              ),
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const Failure(
          code: FailureCode.authProviderDisabled,
          message: 'Apple tidak mengembalikan identity token.',
          kind: FailureKind.authentication,
        );
      }
      final name = <String?>[
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
      return SocialCredential(
        provider: SocialProvider.apple,
        idToken: idToken,
        accessToken: credential.authorizationCode,
        email: credential.email,
        displayName: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      throw PlatformException(code: error.code.name, message: error.message);
    } on SignInWithAppleException catch (error) {
      throw PlatformException(code: 'apple_exception', message: '$error');
    }
  }
}
