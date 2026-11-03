import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

import 'biometric_availability.dart';
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

  /// Turns off automatically when the device has no usable biometrics.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  DateTime? _pausedAt;
  bool _initialized = false;

  bool get isLocked => locked.value;

  /// Checks the device once and disables locking when biometrics are absent.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    try {
      final availability = await gate.biometric.availability();
      enabled.value = availability == BiometricAvailability.available;
    } on Object {
      enabled.value = false;
    }
    if (!enabled.value) {
      locked.value = false;
    }
  }

  void onPause([DateTime? now]) {
    if (!enabled.value) {
      return;
    }
    _pausedAt = now ?? clock.now();
  }

  Future<void> onResume([DateTime? now]) async {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null || !enabled.value) {
      return;
    }
    final elapsed = (now ?? clock.now()).difference(pausedAt);
    if (elapsed >= config.gracePeriod) {
      lock();
    }
  }

  void lock() {
    if (!enabled.value) {
      return;
    }
    locked.value = true;
  }

  Future<bool> unlock() async {
    if (!enabled.value) {
      locked.value = false;
      return true;
    }
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
    enabled.dispose();
  }
}
