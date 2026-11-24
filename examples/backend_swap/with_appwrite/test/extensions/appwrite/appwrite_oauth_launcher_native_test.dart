import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_oauth_launcher_native.dart';

final class ProjectClient implements Client {
  @override
  Map<String, String> config = {'project': 'project'};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class RecordingAccount extends Account {
  RecordingAccount() : super(ProjectClient());
  OAuthProvider? provider;
  String? success;
  String? failure;
  int calls = 0;
  @override
  Future<void> createOAuth2Session({
    required OAuthProvider provider,
    String? success,
    String? failure,
    List<String>? scopes,
    String? state,
  }) async {
    calls++;
    this.provider = provider;
    this.success = success;
    this.failure = failure;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native login omits redirect arguments so SDK receives session credentials',
    () async {
      final account = RecordingAccount();
      await launchAppwriteOAuth(
        account,
        provider: OAuthProvider.google,
        successUrl: 'appwrite-callback-project://',
      );
      expect(account.calls, 1);
      expect(account.provider, OAuthProvider.google);
      expect(account.success, isNull);
      expect(account.failure, isNull);
    },
  );

  test(
    'unsupported native redirect fails before opening the browser',
    () async {
      final account = RecordingAccount();
      await expectLater(
        launchAppwriteOAuth(
          account,
          provider: OAuthProvider.google,
          successUrl: 'https://example.com/callback',
        ),
        throwsArgumentError,
      );
      expect(account.calls, 0);
    },
  );
}
