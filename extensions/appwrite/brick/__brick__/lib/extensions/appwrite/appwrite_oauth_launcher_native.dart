import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';

Future<void> launchAppwriteOAuth(
  Account account, {
  required OAuthProvider provider,
  required String successUrl,
  String? failureUrl,
}) async {
  final callback = 'appwrite-callback-${account.client.config['project']}://';
  if (successUrl != callback ||
      (failureUrl != null && failureUrl != callback)) {
    throw ArgumentError(
      'Native OAuth requires the default Appwrite callback. '
      'Custom redirect URLs are supported only on web.',
    );
  }
  // Only the server's default native redirect carries the session credentials.
  // Passing even the matching custom scheme as `success` suppresses them.
  await account.createOAuth2Session(provider: provider);
}

void cancelAppwriteOAuth(Account account) {}
