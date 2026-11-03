import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_storage_config.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_storage_module.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_storage_support.dart';

void main() {
  test('module registers SecureStorage and config', () {
    final registry = GetItRegistry();

    const SecureStorageModule().register(registry);

    expect(registry.read<SecureStorage>(), isA<SecureStorage>());
    expect(registry.read<SecureStorageConfig>().prefix, isNotEmpty);
    expect(registry.read<SecureStorageSupport>(), isA<SecureStorageSupport>());
  });
}
