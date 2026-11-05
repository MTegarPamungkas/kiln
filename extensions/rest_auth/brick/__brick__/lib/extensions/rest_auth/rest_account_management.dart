import 'package:kiln_core/kiln_core.dart';

import 'rest_auth.dart';
import 'rest_auth_config.dart';

/// Account operations exposed by optional REST endpoints.
final class RestAccountManagement implements AccountManagement {
  const RestAccountManagement({required this.auth, required this.config});

  final RestAuth auth;
  final RestAuthConfig config;

  @override
  bool get isEmailVerified =>
      auth.currentSession?.metadata['emailVerified'] == true;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    _requirePath(config.forgotPasswordPath);
    await auth.request(
      HttpMethod.post,
      config.forgotPasswordPath,
      body: <String, Object?>{'email': email},
      authenticated: false,
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    _requirePath(config.verifyEmailPath);
    await auth.request(
      HttpMethod.post,
      config.verifyEmailPath,
      body: const <String, Object?>{},
    );
  }

  @override
  Future<void> reloadUser() => auth.reloadSession();

  @override
  Future<void> updateDisplayName(String displayName) async {
    await auth.request(
      HttpMethod.patch,
      config.mePath,
      body: <String, Object?>{'displayName': displayName},
    );
    await auth.reloadSession();
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) async {
    await auth.request(
      HttpMethod.patch,
      config.mePath,
      body: <String, Object?>{'photoUrl': photoUrl},
    );
    await auth.reloadSession();
  }

  void _requirePath(String path) {
    if (path.isEmpty) {
      throw const Failure(
        code: FailureCode.configurationMissing,
        message: 'This endpoint is not configured.',
        kind: FailureKind.configuration,
      );
    }
  }
}
