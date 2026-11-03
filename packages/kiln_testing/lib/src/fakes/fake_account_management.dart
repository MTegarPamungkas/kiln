import 'package:kiln_core/kiln_core.dart';

/// Records account operations without calling a backend.
final class FakeAccountManagement implements AccountManagement {
  FakeAccountManagement({this.isEmailVerified = false, this.failure});

  final List<String> calls = <String>[];
  @override
  bool isEmailVerified;
  Failure? failure;
  String? displayName;
  String? photoUrl;

  void _maybeFail() {
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    calls.add('reset:$email');
    _maybeFail();
  }

  @override
  Future<void> sendEmailVerification() async {
    calls.add('verify');
    _maybeFail();
  }

  @override
  Future<void> reloadUser() async {
    calls.add('reload');
    _maybeFail();
  }

  @override
  Future<void> updateDisplayName(String newDisplayName) async {
    calls.add('displayName:$newDisplayName');
    _maybeFail();
    displayName = newDisplayName;
  }

  @override
  Future<void> updatePhotoUrl(String? newPhotoUrl) async {
    calls.add('photoUrl:$newPhotoUrl');
    _maybeFail();
    photoUrl = newPhotoUrl;
  }
}
