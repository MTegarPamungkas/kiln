import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'notification_gateway.dart';

/// Probes whether local notifications can run on this platform/device.
///
/// The probe initializes the plugin without prompting for permission. A
/// missing plugin, an unsupported desktop service, or an initialization error
/// becomes an informational [SupportInfo] instead of a startup crash.
final class NotificationSupport {
  NotificationSupport({required this.gateway});

  final NotificationGateway gateway;
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
      await gateway.initialize();
      return const SupportInfo.supported();
    } on MissingPluginException catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Local notifications are not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on UnsupportedError catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Local notifications are not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Local notifications could not start: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
