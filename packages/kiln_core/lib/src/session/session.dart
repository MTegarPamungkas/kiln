import '../util/clock.dart';

/// Identity of the signed-in user for the current session.
final class AuthSession {
  const AuthSession({
    required this.userId,
    this.expiresAt,
    this.email,
    this.displayName,
    this.metadata = const <String, Object?>{},
  });

  final String userId;
  final DateTime? expiresAt;
  final String? email;
  final String? displayName;
  final Map<String, Object?> metadata;

  bool isExpired(Clock clock, {Duration leeway = Duration.zero}) {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }
    return !expiry.isAfter(clock.now().add(leeway));
  }

  AuthSession copyWith({
    String? userId,
    DateTime? expiresAt,
    String? email,
    String? displayName,
    Map<String, Object?>? metadata,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      expiresAt: expiresAt ?? this.expiresAt,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.expiresAt == expiresAt &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(userId, expiresAt, email, displayName);

  @override
  String toString() => 'AuthSession($userId)';
}
