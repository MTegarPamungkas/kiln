import 'dart:async';

import '../errors/failure.dart';
import '../errors/failure_codes.dart';

/// Why an extension can or cannot be used on the current device.
enum SupportState {
  supported,
  unsupportedPlatform,
  unsupportedDevice,
  permissionDenied,
  notConfigured,
  unavailable,
}

/// Runtime support information for one extension.
///
/// Extensions probe the platform and the device during bootstrap. The result
/// is recorded in [SupportRegistry], so the application can show information
/// instead of checking platform and hardware itself.
final class SupportInfo {
  const SupportInfo.supported({
    this.message = 'Supported',
    this.details = const <String, Object?>{},
  }) : state = SupportState.supported;

  const SupportInfo.unsupported(
    this.state, {
    required this.message,
    this.details = const <String, Object?>{},
  }) : assert(state != SupportState.supported);

  final SupportState state;
  final String message;
  final Map<String, Object?> details;

  bool get isSupported => state == SupportState.supported;

  bool get isPlatformUnsupported => state == SupportState.unsupportedPlatform;

  bool get isDeviceUnsupported => state == SupportState.unsupportedDevice;

  /// Converts this support result into a typed [Failure].
  ///
  /// Use it when a call cannot proceed on this platform or device, so callers
  /// receive an explanatory result instead of a generic crash.
  Failure toFailure({String? message}) {
    return Failure(
      code: switch (state) {
        SupportState.unsupportedPlatform => FailureCode.unsupportedPlatform,
        SupportState.unsupportedDevice => FailureCode.unsupportedDevice,
        SupportState.notConfigured => FailureCode.configurationMissing,
        SupportState.permissionDenied => FailureCode.permissionDenied,
        SupportState.unavailable => FailureCode.unavailable,
        SupportState.supported => FailureCode.unavailable,
      },
      message: message ?? this.message,
      kind: switch (state) {
        SupportState.unsupportedPlatform ||
        SupportState.unsupportedDevice => FailureKind.unsupported,
        SupportState.notConfigured => FailureKind.configuration,
        SupportState.permissionDenied => FailureKind.permission,
        SupportState.unavailable => FailureKind.unavailable,
        SupportState.supported => FailureKind.unknown,
      },
      details: <String, Object?>{'support_state': state.name, ...details},
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SupportInfo && other.state == state && other.message == message;

  @override
  int get hashCode => Object.hash(state, message);

  @override
  String toString() => 'SupportInfo(${state.name}): $message';
}

/// Records the support state reported by every extension module.
///
/// The registry is created by `KilnBootstrap`, so application code can read it
/// without wiring anything:
///
/// ```dart
/// final support = registry.read<SupportRegistry>();
/// final biometric = support['biometric'];
/// ```
final class SupportRegistry {
  final Map<String, SupportInfo> _entries = <String, SupportInfo>{};
  final StreamController<Map<String, SupportInfo>> _changes =
      StreamController<Map<String, SupportInfo>>.broadcast(sync: true);

  SupportInfo? operator [](String extensionId) => _entries[extensionId];

  Map<String, SupportInfo> get all =>
      Map<String, SupportInfo>.unmodifiable(_entries);

  Stream<Map<String, SupportInfo>> get changes => _changes.stream;

  void record(String extensionId, SupportInfo info) {
    _entries[extensionId] = info;
    _changes.add(all);
  }

  Future<void> dispose() => _changes.close();
}
