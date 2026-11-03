import 'package:kiln_core/kiln_core.dart';

import 'firebase_failure_mapper.dart';
import 'firebase_gateway.dart';

/// [AccountManagement] backed by the signed-in Firebase user.
final class FirebaseAccountManagement implements AccountManagement {
  const FirebaseAccountManagement({
    required this.gateway,
    this.failureMapper = mapFirebaseError,
  });

  final FirebaseAuthGateway gateway;
  final FirebaseFailureMapper failureMapper;

  @override
  bool get isEmailVerified => gateway.currentUser?.emailVerified ?? false;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _run(() => gateway.sendPasswordResetEmail(email));
  }

  @override
  Future<void> sendEmailVerification() async {
    await _run(gateway.sendEmailVerification);
  }

  @override
  Future<void> reloadUser() async {
    await _run(gateway.reloadUser);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await _run(() => gateway.updateDisplayName(displayName));
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) async {
    await _run(() => gateway.updatePhotoUrl(photoUrl));
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }
}
