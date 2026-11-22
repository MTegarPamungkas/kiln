import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// Merges foreground taps, background taps, and the launch payload.
final class NotificationTapHub {
  NotificationTapHub({
    Stream<String?>? foreground,
    Stream<String?>? background,
    this.launchPayload,
  }) {
    _taps = StreamController<NotificationTap>.broadcast(
      sync: true,
      onListen: _flushPending,
    );
    if (foreground != null) {
      _subscriptions.add(foreground.listen(_emit));
    }
    if (background != null) {
      _subscriptions.add(background.listen(_emit));
    }
  }

  String? launchPayload;
  late final StreamController<NotificationTap> _taps;
  final List<StreamSubscription<String?>> _subscriptions =
      <StreamSubscription<String?>>[];
  final List<NotificationTap> _pending = <NotificationTap>[];
  bool _launchEmitted = false;
  bool _started = false;
  bool _disposed = false;

  /// Taps for the first listener, including a launch payload and taps that
  /// arrived while no consumer was ready. The replay happens once; later
  /// listeners only receive live taps.
  Stream<NotificationTap> get taps => _taps.stream;

  void _flushPending() {
    // Do not emit before listen() returns on a synchronous stream.
    scheduleMicrotask(() {
      if (_disposed || !_taps.hasListener) return;
      final pending = List<NotificationTap>.of(_pending);
      _pending.clear();
      for (final tap in pending) {
        if (_disposed || !_taps.hasListener) break;
        _taps.add(tap);
      }
    });
  }

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
    if (_disposed || _taps.isClosed) {
      return;
    }
    final tap = NotificationTap(payload);
    if (!_taps.hasListener || _pending.isNotEmpty) {
      _pending.add(tap);
      return;
    }
    _taps.add(tap);
  }

  Future<void> dispose() async {
    _disposed = true;
    _pending.clear();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _taps.close();
  }
}
