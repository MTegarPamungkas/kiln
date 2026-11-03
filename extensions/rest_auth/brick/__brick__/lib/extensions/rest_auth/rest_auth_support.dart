import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'rest_auth_config.dart';

typedef RestAuthStorageProbe = Future<void> Function();

/// Validates REST auth configuration and the secure token store.
final class RestAuthSupport {
  RestAuthSupport({required this.config, this.storageProbe});

  final RestAuthConfig config;
  final RestAuthStorageProbe? storageProbe;
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
    final problem = config.validate();
    if (problem != null) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: problem.message,
        details: <String, Object?>{'code': problem.code.value},
      );
    }
    final probe = storageProbe;
    if (probe != null) {
      try {
        await probe();
      } on MissingPluginException catch (error) {
        return SupportInfo.unsupported(
          SupportState.unsupportedPlatform,
          message: 'Secure storage for REST auth is not available.',
          details: <String, Object?>{'error': '$error'},
        );
      } on UnsupportedError catch (error) {
        return SupportInfo.unsupported(
          SupportState.unsupportedPlatform,
          message: 'Secure storage for REST auth is not available.',
          details: <String, Object?>{'error': '$error'},
        );
      } on Failure catch (failure) {
        return SupportInfo.unsupported(
          SupportState.unavailable,
          message: failure.message,
          details: <String, Object?>{'code': failure.code.value},
        );
      } on Object catch (error) {
        return SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'REST auth storage could not be read: $error',
          details: <String, Object?>{'error': '$error'},
        );
      }
    }
    final uri = Uri.tryParse(config.baseUrl);
    return SupportInfo.supported(details: <String, Object?>{'host': uri?.host});
  }
}
