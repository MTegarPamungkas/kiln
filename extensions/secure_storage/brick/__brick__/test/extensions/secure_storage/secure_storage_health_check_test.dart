import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_storage_health_check.dart';

final class _FailingSecureStorage implements SecureStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async {
    throw const Failure(
      code: FailureCode.secureStorageUnavailable,
      message: 'unavailable',
      kind: FailureKind.storage,
    );
  }

  @override
  Future<Map<String, String>> readAll() async => const {};

  @override
  Future<void> write(String key, String value) async {}
}

void main() {
  test('reports success and logs it', () async {
    final logger = RecordingLogger();
    final healthy = await const SecureStorageHealthCheck().run(
      InMemorySecureStorage(),
      logger: logger,
    );

    expect(healthy, isTrue);
    expect(logger.messages.join('\n'), contains('passed'));
  });

  test('reports failure without throwing', () async {
    final logger = RecordingLogger();
    final healthy = await const SecureStorageHealthCheck().run(
      _FailingSecureStorage(),
      logger: logger,
    );

    expect(healthy, isFalse);
    expect(logger.messages.join('\n'), contains('failed'));
  });
}
