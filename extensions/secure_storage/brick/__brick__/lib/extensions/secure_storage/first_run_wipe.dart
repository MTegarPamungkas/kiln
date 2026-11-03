import 'package:kiln_core/kiln_core.dart';

import 'secure_storage_gateway.dart';

/// Deletes leftover Keychain entries after a reinstall on iOS.
final class FirstRunWipe {
  FirstRunWipe({
    required this.gateway,
    required this.storage,
    this.markerKey = 'secure_storage.first_run_wiped',
  });

  final SecureStorageGateway gateway;
  final Storage storage;
  final String markerKey;

  Future<bool> run({required bool isIOS}) async {
    if (!isIOS) {
      return false;
    }
    if (await storage.read(markerKey) == 'true') {
      return false;
    }
    final values = await gateway.readAll();
    for (final key in values.keys) {
      await gateway.delete(key);
    }
    await storage.write(markerKey, 'true');
    return true;
  }
}
