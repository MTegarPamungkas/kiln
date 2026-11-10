import 'package:flutter/services.dart' show MissingPluginException;
import 'package:kiln_core/kiln_core.dart';

import 'secure_storage_gateway.dart';

/// Probes whether the platform secure store (Keychain/Keystore/WebCrypto) works.
///
/// The probe reads all namespaced values without writing, so it is safe to run
/// during bootstrap. A missing plugin or an unavailable desktop service becomes
/// an informational [SupportInfo] instead of a startup failure.
final class SecureStorageSupport {
  SecureStorageSupport({required this.gateway});

  final SecureStorageGateway gateway;
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
      await gateway.readAll();
      return const SupportInfo.supported();
    } on MissingPluginException catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Secure storage is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on UnsupportedError catch (error) {
      return SupportInfo.unsupported(
        SupportState.unsupportedPlatform,
        message: 'Secure storage is not implemented on this platform.',
        details: <String, Object?>{'error': '$error'},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.unavailable,
        message: 'Secure storage service is unavailable: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
