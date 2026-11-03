import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'permission_config.dart';
import 'permission_gateway.dart';

/// Resolves whether a permission kind exists on the current platform/device.
///
/// Platform support alone is not enough: a desktop without a camera, a web
/// build without contacts, or a restricted device all need an informational
/// answer instead of a crash. The probe reads the real status once, caches it,
/// and maps plugin errors to support states.
final class PermissionSupport {
  PermissionSupport({required this.config, required this.gateway});

  final PermissionConfig config;
  final PermissionGateway gateway;
  final Map<PermissionKind, SupportInfo> _cache =
      <PermissionKind, SupportInfo>{};

  /// Checks one kind. Safe to call before any permission prompt.
  Future<SupportInfo> forKind(PermissionKind kind) async {
    final cached = _cache[kind];
    if (cached != null) {
      return cached;
    }
    final info = await _probe(kind);
    _cache[kind] = info;
    return info;
  }

  /// Probes every kind enabled in [config].
  Future<Map<PermissionKind, SupportInfo>> probeAll() async {
    for (final kind in config.activeKinds) {
      await forKind(kind);
    }
    return Map<PermissionKind, SupportInfo>.unmodifiable(_cache);
  }

  /// Configuration-only answer without touching the plugin.
  SupportInfo configured(PermissionKind kind) {
    if (!config.activeKinds.contains(kind)) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: 'Permission "$kind" is not enabled for this app.',
        details: <String, Object?>{'kind': kind.name},
      );
    }
    return const SupportInfo.supported();
  }

  void clear() => _cache.clear();

  Future<SupportInfo> _probe(PermissionKind kind) async {
    final configuredInfo = configured(kind);
    if (!configuredInfo.isSupported) {
      return configuredInfo;
    }
    try {
      final status = await gateway.status(kind);
      return switch (status) {
        PermissionStatus.restricted => SupportInfo.unsupported(
          SupportState.unsupportedDevice,
          message: 'Permission "$kind" is restricted on this device.',
          details: <String, Object?>{'kind': kind.name},
        ),
        PermissionStatus.unsupported => SupportInfo.unsupported(
          SupportState.unsupportedDevice,
          message: 'Permission "$kind" is not supported on this device.',
          details: <String, Object?>{'kind': kind.name},
        ),
        _ => const SupportInfo.supported(),
      };
    } on MissingPluginException catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Permission "$kind" is not implemented on this platform.',
        details: <String, Object?>{'kind': kind.name, 'error': '$error'},
      );
    } on UnsupportedError catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Permission "$kind" is not implemented on this platform.',
        details: <String, Object?>{'kind': kind.name, 'error': '$error'},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Could not read permission "$kind": $error',
        details: <String, Object?>{'kind': kind.name, 'error': '$error'},
      );
    }
  }
}
