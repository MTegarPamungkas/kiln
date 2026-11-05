import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Port that carries background taps back to the running app.
const notificationTapPortName = 'kiln.notifications.taps';

/// Receives taps for actions that do not open the app.
@pragma('vm:entry-point')
void notificationBackgroundTap(NotificationResponse response) {
  final port = IsolateNameServer.lookupPortByName(notificationTapPortName);
  port?.send(response.payload);
}
