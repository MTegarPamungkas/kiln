/// A device registered to receive push notifications for the signed-in user.
final class PushTarget {
  const PushTarget({
    required this.id,
    required this.identifier,
    this.providerId,
    this.name,
    this.userId,
    this.expired = false,
  });

  /// Backend-assigned target id.
  final String id;

  /// The device token (FCM/APNs) messages are delivered to.
  final String identifier;

  /// Messaging provider the target is bound to, when the backend uses one.
  final String? providerId;

  /// Human-readable target name, when the backend reports one.
  final String? name;

  /// Backend user id the target belongs to.
  final String? userId;

  /// Whether the token has expired and needs re-registration.
  final bool expired;
}

/// Registers device push targets for the signed-in user.
///
/// This capability manages the *address book*: it stores the device token on
/// the backend so the backend can deliver pushes later. It does not send or
/// receive messages — delivery transport (FCM/APNs) and message handling live
/// outside this contract.
abstract interface class PushTargets {
  /// Registers or updates the device token for the current session.
  ///
  /// Backends keep one target per provider per session: registering again
  /// with a rotated token updates the existing target instead of creating a
  /// duplicate, so a device is never notified twice.
  Future<PushTarget> register({
    required String token,
    String? providerId,
  });

  /// Replaces the token of an existing [targetId].
  Future<PushTarget> update({
    required String targetId,
    required String token,
  });

  /// Removes the target; the device stops receiving pushes.
  Future<void> unregister({required String targetId});
}
