import 'package:kiln_core/kiln_core.dart';

import 'secure_storage_gateway.dart';

/// Deletes leftover Keychain entries after a reinstall on iOS.
///
/// Only keys owned by [prefix] are removed; entries written by another app or
/// access group survive. The marker is written after every owned key was
/// deleted, so an interrupted cleanup runs again on the next launch.
final class FirstRunWipe {
  FirstRunWipe({
    required this.gateway,
    required this.storage,
    required this.prefix,
    this.markerKey = 'secure_storage.first_run_wiped',
  });

  final SecureStorageGateway gateway;
  final Storage storage;
  final String prefix;
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
      if (!key.startsWith(prefix)) {
        continue;
      }
      await gateway.delete(key);
    }
    await storage.write(markerKey, 'true');
    return true;
  }
}
