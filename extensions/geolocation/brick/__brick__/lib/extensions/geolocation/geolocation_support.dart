import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'location_gateway.dart';

/// Reports whether location services and permission are usable now.
final class GeolocationSupport {
  GeolocationSupport({required this.gateway, this.permissions});

  final LocationGateway gateway;
  final Permissions? permissions;
  SupportInfo? _last;

  Future<SupportInfo> check() async {
    final last = _last;
    if (last != null) {
      return last;
    }
    final info = await _probe();
    _last = info;
    return info;
  }

  void clear() => _last = null;

  Future<SupportInfo> _probe() async {
    try {
      if (!await gateway.isServiceEnabled()) {
        return const SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Location services are turned off on this device.',
        );
      }
      final contract = permissions;
      if (contract != null) {
        final status = await contract.status(PermissionKind.location);
        if (status.isGranted) {
          return const SupportInfo.supported();
        }
        return SupportInfo.unsupported(
          status.isUnsupported
              ? SupportState.unsupportedDevice
              : SupportState.permissionDenied,
          message: 'Location permission is ${status.name}.',
        );
      }
      final permission = await gateway.permission();
      if (permission == LocationPermissionState.granted) {
        return const SupportInfo.supported();
      }
      return SupportInfo.unsupported(
        SupportState.permissionDenied,
        message: 'Location permission is ${permission.name}.',
      );
    } on MissingPluginException catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Geolocation is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on UnsupportedError catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Geolocation is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Location services are unavailable: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
