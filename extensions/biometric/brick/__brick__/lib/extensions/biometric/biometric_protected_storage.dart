import 'package:kiln_core/kiln_core.dart';

import 'biometric.dart';

/// [SecureStorage] that asks for biometrics before reading a value.
final class BiometricProtectedStorage implements SecureStorage {
  const BiometricProtectedStorage({
    required this.storage,
    required this.biometric,
  });

  final SecureStorage storage;
  final Biometric biometric;

  @override
  Future<String?> read(String key) async {
    final authenticated = await biometric.authenticate();
    if (!authenticated) {
      throw const Failure(
        code: FailureCode.permissionDenied,
        message: 'Autentikasi biometrik diperlukan untuk membaca data.',
        kind: FailureKind.permission,
      );
    }
    return storage.read(key);
  }

  @override
  Future<void> write(String key, String value) => storage.write(key, value);

  @override
  Future<void> delete(String key) => storage.delete(key);

  @override
  Future<Map<String, String>> readAll() => storage.readAll();

  @override
  Future<void> clear() => storage.clear();
}
