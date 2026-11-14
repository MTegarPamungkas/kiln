import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_push_background.dart' as background;
import 'appwrite_push_transport.dart';

/// Registers the FCM push transport for Appwrite.
///
/// Requires the `appwrite` extension: the transport mints the device token
/// and keeps the backend push target in sync through its `PushTargets`
/// capability. When the `notifications` extension is installed, foreground
/// messages are additionally surfaced as local notifications.
final class AppwritePushModule extends KilnModule {
  AppwritePushModule({this.autoRegister = true});

  /// Whether [AppwritePushTransport.initialize] registers the FCM token on
  /// the signed-in user's account automatically. Turn this off to opt into
  /// explicit registration from the application.
  final bool autoRegister;

  AppwritePushTransport? _transport;

  @override
  String get id => 'appwrite_push';

  @override
  Set<String> get requires => const <String>{'push_targets'};

  @override
  Set<String> get optionalRequires => const <String>{'notifications'};

  @override
  Set<String> get provides => const <String>{'push_transport'};

  @override
  void register(Registry registry) {
    final transport = AppwritePushTransport(
      pushTargets: registry.read<PushTargets>(),
      notifications: registry.readOrNull<Notifications>(),
    );
    _transport = transport;
    registry
      ..registerSingleton<AppwritePushTransport>(transport)
      ..registerSingleton<PushTransport>(transport);
  }

  @override
  Future<void> ready(Registry registry) async {
    final transport = _transport;
    if (transport == null || !autoRegister) {
      return;
    }
    try {
      await transport.initialize();
      // Appwrite delivers data payloads, so background pushes render through
      // the system tray via this handler (foreground goes to the stream).
      FirebaseMessaging.onBackgroundMessage(
        background.appwritePushBackgroundHandler,
      );
    } on Failure catch (failure) {
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Push transport unavailable: ${failure.message}',
          details: <String, Object?>{'code': failure.code.value},
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _transport?.dispose();
    _transport = null;
  }
}
