import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// Merges foreground taps, background taps, and the launch payload.
final class NotificationTapHub {
  NotificationTapHub({
    Stream<String?>? foreground,
    Stream<String?>? background,
    this.launchPayload,
  }) {
    if (foreground != null) {
      _subscriptions.add(foreground.listen(_emit));
    }
    if (background != null) {
      _subscriptions.add(background.listen(_emit));
    }
  }

  String? launchPayload;
  final StreamController<NotificationTap> _taps =
      StreamController<NotificationTap>.broadcast(sync: true);
  final List<StreamSubscription<String?>> _subscriptions =
      <StreamSubscription<String?>>[];
  bool _launchEmitted = false;
  bool _started = false;

  Stream<NotificationTap> get taps => _taps.stream;

  void setLaunchPayload(String? payload) {
    launchPayload = payload;
  }

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    final payload = launchPayload;
    if (!_launchEmitted && payload != null && payload.isNotEmpty) {
      _launchEmitted = true;
      _emit(payload);
    }
  }

  void add(String? payload) => _emit(payload);

  void _emit(String? payload) {
    if (!_taps.isClosed) {
      _taps.add(NotificationTap(payload));
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _taps.close();
  }
}
