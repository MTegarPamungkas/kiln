import 'package:kiln_core/kiln_core.dart';

/// [SocialAuth] with configurable success, cancellation, and failure.
final class FakeSocialAuth implements SocialAuth {
  FakeSocialAuth({this.credential, this.failure, this.cancelled = false});

  final List<String> calls = <String>[];
  SocialCredential? credential;
  Failure? failure;
  bool cancelled;

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async {
    calls.add('signIn:${provider.name}');
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    if (cancelled) {
      return null;
    }
    return credential ??
        SocialCredential(provider: provider, idToken: 'token-${provider.name}');
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
  }
}
