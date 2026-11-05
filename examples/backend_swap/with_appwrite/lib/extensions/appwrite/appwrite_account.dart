import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

/// User fields the extension needs, independent of the Appwrite models.
final class AppwriteAccountUser {
  const AppwriteAccountUser({
    required this.id,
    required this.email,
    this.name = '',
    this.emailVerified = false,
    this.prefs = const <String, Object?>{},
  });

  final String id;
  final String email;
  final String name;
  final bool emailVerified;
  final Map<String, Object?> prefs;

  String? get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? get photoUrl {
    final value = prefs['photoUrl'];
    return value is String && value.isNotEmpty ? value : null;
  }

  AppwriteAccountUser copyWith({
    String? name,
    bool? emailVerified,
    Map<String, Object?>? prefs,
  }) {
    return AppwriteAccountUser(
      id: id,
      email: email,
      name: name ?? this.name,
      emailVerified: emailVerified ?? this.emailVerified,
      prefs: prefs ?? this.prefs,
    );
  }
}

/// Session handle returned by the Appwrite account service.
final class AppwriteAccountSession {
  const AppwriteAccountSession({
    required this.id,
    required this.userId,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final DateTime? expiresAt;
}

/// The user and session produced by a sign-in.
final class AppwriteAuthResult {
  const AppwriteAuthResult({required this.user, required this.session});

  final AppwriteAccountUser user;
  final AppwriteAccountSession session;
}

/// Appwrite account calls the rest of the extension depends on.
///
/// The interface keeps SDK models out of the auth and account code so both can
/// be exercised with an in-memory fake.
abstract interface class AppwriteAccount {
  /// The signed-in user, or null when the current session is gone.
  Future<AppwriteAccountUser?> currentUser();

  Future<AppwriteAuthResult> signIn({
    required String email,
    required String password,
  });

  Future<AppwriteAccountUser> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(
    String email, {
    required String redirectUrl,
  });

  Future<void> sendEmailVerification({required String redirectUrl});

  Future<void> updateDisplayName(String displayName);

  Future<void> updatePhotoUrl(String? photoUrl);

  /// Creates a short-lived JWT for the current session, or null when signed out.
  Future<String?> createJwt();
}

/// [AppwriteAccount] on top of the Appwrite `Account` service.
final class SdkAppwriteAccount implements AppwriteAccount {
  SdkAppwriteAccount({required this.account});

  final Account account;

  @override
  Future<AppwriteAccountUser?> currentUser() async {
    try {
      return _fromUser(await account.get());
    } on AppwriteException catch (error) {
      if (error.code == 401) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AppwriteAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final session = await account.createEmailPasswordSession(
      email: email,
      password: password,
    );
    final user = await account.get();
    return AppwriteAuthResult(
      user: _fromUser(user),
      session: _fromSession(session),
    );
  }

  @override
  Future<AppwriteAccountUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: displayName,
    );
    return _fromUser(user);
  }

  @override
  Future<void> signOut() async {
    try {
      await account.deleteSessions(current: true);
    } on AppwriteException catch (error) {
      if (error.code != 401) {
        rethrow;
      }
    }
  }

  @override
  Future<void> sendPasswordResetEmail(
    String email, {
    required String redirectUrl,
  }) async {
    await account.createRecovery(email: email, url: redirectUrl);
  }

  @override
  Future<void> sendEmailVerification({required String redirectUrl}) async {
    await account.createEmailVerification(url: redirectUrl);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await account.updateName(name: displayName);
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) async {
    final current = await account.getPrefs();
    final prefs = Map<String, Object?>.from(current.data);
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      prefs.remove('photoUrl');
    } else {
      prefs['photoUrl'] = photoUrl;
    }
    await account.updatePrefs(prefs: prefs);
  }

  @override
  Future<String?> createJwt() async {
    try {
      final token = await account.createJWT();
      return token.jwt.isEmpty ? null : token.jwt;
    } on AppwriteException catch (error) {
      if (error.code == 401) {
        return null;
      }
      rethrow;
    }
  }

  AppwriteAccountUser _fromUser(models.User user) {
    return AppwriteAccountUser(
      id: user.$id,
      email: user.email,
      name: user.name,
      emailVerified: user.emailVerification,
      prefs: Map<String, Object?>.from(user.prefs.data),
    );
  }

  AppwriteAccountSession _fromSession(models.Session session) {
    return AppwriteAccountSession(
      id: session.$id,
      userId: session.userId,
      expiresAt: DateTime.tryParse(session.expire),
    );
  }
}
