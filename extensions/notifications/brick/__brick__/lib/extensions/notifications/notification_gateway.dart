import 'package:kiln_core/kiln_core.dart';

/// One notification handed to a gateway.
final class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.channelId,
  });

  final int id;
  final String title;
  final String body;
  final String? payload;
  final String? channelId;
}

/// Platform notification access that can be faked in tests.
abstract interface class NotificationGateway {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> show(NotificationRequest request);

  Future<void> schedule(NotificationRequest request, DateTime when);

  Future<void> cancel(int id);

  Future<void> cancelAll();

  Stream<NotificationTap> get taps;

  /// The payload that launched the app, read after [initialize].
  String? get launchPayload;

  Future<void> dispose();
}
