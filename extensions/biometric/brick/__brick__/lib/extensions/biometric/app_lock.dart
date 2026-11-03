import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

import 'biometric_config.dart';
import 'biometric_gate.dart';

/// Locks the app after it stays in the background past the grace period.
final class AppLock {
  AppLock({
    required this.gate,
    this.config = BiometricConfig.defaults,
    this.clock = const SystemClock(),
  });

  final BiometricGate gate;
  final BiometricConfig config;
  final Clock clock;
  final ValueNotifier<bool> locked = ValueNotifier<bool>(false);
  DateTime? _pausedAt;

  bool get isLocked => locked.value;

  void onPause([DateTime? now]) {
    _pausedAt = now ?? clock.now();
  }

  Future<void> onResume([DateTime? now]) async {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) {
      return;
    }
    final elapsed = (now ?? clock.now()).difference(pausedAt);
    if (elapsed >= config.gracePeriod) {
      lock();
    }
  }

  void lock() {
    locked.value = true;
  }

  Future<bool> unlock() async {
    try {
      gate.reset();
      await gate.ensureAuthenticated();
      locked.value = false;
      return true;
    } on Failure {
      return false;
    }
  }

  void dispose() {
    locked.dispose();
  }
}
