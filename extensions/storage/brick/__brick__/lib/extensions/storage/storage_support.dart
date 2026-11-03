import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'storage_gateway.dart';

/// Probes whether the platform key-value store can be read.
final class StorageSupport {
  StorageSupport({required this.gateway});

  final StorageGateway gateway;
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
      await gateway.keys();
      return const SupportInfo.supported(
        details: <String, Object?>{'backend': 'shared_preferences'},
      );
    } on MissingPluginException catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Key-value storage is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on UnsupportedError catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Key-value storage is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Key-value storage is unavailable: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
