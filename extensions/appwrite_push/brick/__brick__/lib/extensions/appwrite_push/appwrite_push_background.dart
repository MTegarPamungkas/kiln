import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Appwrite delivers pushes that carry a notification payload, which the
/// platform auto-displays while the app is backgrounded — the handler only
/// renders data-only pushes, otherwise the tray entry appears twice.
///
/// Registered by [AppwritePushModule] during bootstrap; the function must be
/// top-level so the background isolate can resolve it.
@pragma('vm:entry-point')
Future<void> appwritePushBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    return;
  }
  await Firebase.initializeApp();
  final plugin = FlutterLocalNotificationsPlugin();
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await plugin.initialize(settings: settings);

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'appwrite_push',
      'Push',
      channelDescription: 'Push notifications delivered by Appwrite.',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  final notification = message.notification;
  final title = notification?.title ??
      (message.data['title'] as String?) ??
      'New push message';
  final body = notification?.body ??
      (message.data['body'] as String?) ??
      'Tap to open the app.';
  final id = (message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch) %
      2147483647;

  await plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
    payload: jsonEncode(message.data),
  );
}
