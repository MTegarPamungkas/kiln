import 'package:kiln_core/kiln_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appwriteLegacySessionCookieKey = 'kiln.appwrite.session.cookie';

/// Persistence seam for the adapter's session cookie and logout marker.
abstract interface class AppwriteSessionStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Compatibility storage. Values are plaintext; use secure storage when available.
final class PreferencesAppwriteSessionStore implements AppwriteSessionStore {
  const PreferencesAppwriteSessionStore();

  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).get(key)?.toString();

  @override
  Future<void> write(String key, String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(key, value)) {
      throw _storageFailure();
    }
  }

  @override
  Future<void> delete(String key) async {
    if (!await (await SharedPreferences.getInstance()).remove(key)) {
      throw _storageFailure();
    }
  }

  Failure _storageFailure() => const Failure(
    code: FailureCode.unavailable,
    message: 'Appwrite session persistence could not be updated.',
    kind: FailureKind.authentication,
    details: {'localCleanupFailed': true},
  );
}

/// Uses the application's SecureStorage contract without importing its provider.
final class SecureAppwriteSessionStore implements AppwriteSessionStore {
  const SecureAppwriteSessionStore(this.storage);

  final SecureStorage storage;

  @override
  Future<String?> read(String key) async {
    final value = await storage.read(key);
    if (value == null && key.startsWith('kiln.appwrite.signedOut.')) {
      return const PreferencesAppwriteSessionStore().read(key);
    }
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    await storage.write(key, value);
    const previous = PreferencesAppwriteSessionStore();
    await previous.delete(key);
    if (key.startsWith('$appwriteLegacySessionCookieKey.')) {
      await previous.delete(appwriteLegacySessionCookieKey);
    }
  }

  @override
  Future<void> delete(String key) async {
    await Future.wait([
      storage.delete(key),
      const PreferencesAppwriteSessionStore().delete(key),
    ]);
  }
}
