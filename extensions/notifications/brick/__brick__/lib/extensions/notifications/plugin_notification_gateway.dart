import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kiln_core/kiln_core.dart';

import 'background_tap_handler.dart';
import 'notification_channels.dart';
import 'notification_gateway.dart';
import 'notifications_config.dart';
import 'timezone_resolver.dart';

/// NotificationGateway backed by flutter_local_notifications.
final class PluginNotificationGateway implements NotificationGateway {
  PluginNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    this.config = NotificationsConfig.defaults,
    NotificationChannels? channels,
    TimezoneResolver? timezones,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       channels = channels ?? NotificationChannels.defaults(config),
       _timezones = timezones ?? TimezoneResolver();

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationsConfig config;
  final NotificationChannels channels;
  final TimezoneResolver _timezones;
  final StreamController<NotificationTap> _taps =
      StreamController<NotificationTap>.broadcast(sync: true);
  ReceivePort? _backgroundPort;
  StreamSubscription<Object?>? _backgroundSubscription;
  String? _launchPayload;
  bool _initialized = false;

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  @override
  String? get launchPayload => _launchPayload;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await _plugin.initialize(
      settings: _settings,
      onDidReceiveNotificationResponse: _handleTap,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundTap,
    );
    try {
      final port = ReceivePort();
      IsolateNameServer.registerPortWithName(
        port.sendPort,
        notificationTapPortName,
      );
      _backgroundPort = port;
      _backgroundSubscription = port.listen((message) {
        if (message is String) {
          _taps.add(NotificationTap(message));
        }
      });
    } on Object {
      // Background taps need an isolate name server; web and some test hosts
      // do not provide one.
    }
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchPayload = launch!.notificationResponse?.payload;
      }
    } on Object {
      // Launch details are unavailable on platforms without app launching.
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      for (final spec in channels.specs) {
        await android.createNotificationChannel(_androidChannel(spec));
      }
    }
    _initialized = true;
  }

  InitializationSettings get _settings {
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    return InitializationSettings(
      android: AndroidInitializationSettings(config.smallIcon),
      iOS: darwin,
      macOS: darwin,
      linux: const LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      ),
      web: const WebInitializationSettings(),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true, badge: true) ??
          false;
    }
    final macOS = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macOS != null) {
      return await macOS.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    }
    final web = _plugin
        .resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin
        >();
    if (web != null) {
      return await web.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  @override
  Future<void> show(NotificationRequest request) {
    return _plugin.show(
      id: request.id,
      title: request.title,
      body: request.body,
      payload: request.payload,
      notificationDetails: _details(request.channelId),
    );
  }

  @override
  Future<void> schedule(NotificationRequest request, DateTime when) {
    return _plugin.zonedSchedule(
      id: request.id,
      title: request.title,
      body: request.body,
      payload: request.payload,
      notificationDetails: _details(request.channelId),
      scheduledDate: _timezones.toLocal(when),
      androidScheduleMode: config.exactAlarms
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> dispose() async {
    await _backgroundSubscription?.cancel();
    try {
      IsolateNameServer.removePortNameMapping(notificationTapPortName);
    } on Object {
      // No mapping was registered on this platform.
    }
    _backgroundPort?.close();
    await _taps.close();
  }

  void _handleTap(NotificationResponse response) {
    _taps.add(NotificationTap(response.payload));
  }

  AndroidNotificationChannel _androidChannel(NotificationChannelSpec spec) {
    return AndroidNotificationChannel(
      spec.id,
      spec.name,
      description: spec.description,
      importance: _importance(spec.importance),
    );
  }

  NotificationDetails _details(String? channelId) {
    final spec = channels.resolve(channelId);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        spec.id,
        spec.name,
        channelDescription: spec.description,
        importance: _importance(spec.importance),
        priority: _priority(spec.importance),
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
      linux: const LinuxNotificationDetails(),
      windows: const WindowsNotificationDetails(),
      web: const WebNotificationDetails(),
    );
  }

  Importance _importance(NotificationImportance importance) {
    return switch (importance) {
      NotificationImportance.low => Importance.low,
      NotificationImportance.normal => Importance.defaultImportance,
      NotificationImportance.high => Importance.high,
    };
  }

  Priority _priority(NotificationImportance importance) {
    return switch (importance) {
      NotificationImportance.low => Priority.low,
      NotificationImportance.normal => Priority.defaultPriority,
      NotificationImportance.high => Priority.high,
    };
  }
}
