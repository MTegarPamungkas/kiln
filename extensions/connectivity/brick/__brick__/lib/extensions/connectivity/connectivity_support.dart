import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'connectivity_gateway.dart';

/// Probes whether network status monitoring works on this platform.
///
/// Being offline is still supported; only a missing plugin or a failing
/// platform channel makes the extension unsupported.
final class ConnectivitySupport {
  ConnectivitySupport({required this.gateway});

  final ConnectivityGateway gateway;
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
      final status = await gateway.check();
      return SupportInfo.supported(
        details: <String, Object?>{'status': status.name},
      );
    } on MissingPluginException catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Network monitoring is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on UnsupportedError catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Network monitoring is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Network monitoring could not start: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
