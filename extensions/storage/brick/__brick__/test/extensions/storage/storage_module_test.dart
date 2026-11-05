import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/storage/storage_config.dart';
import 'package:{{app_name}}/extensions/storage/storage_migrator.dart';
import 'package:{{app_name}}/extensions/storage/storage_module.dart';
import 'package:{{app_name}}/extensions/storage/storage_support.dart';

void main() {
  test('module registers Storage, config, and migrator', () {
    final registry = GetItRegistry();

    const StorageModule().register(registry);

    expect(registry.read<Storage>(), isA<Storage>());
    expect(registry.read<StorageConfig>().prefix, isNotEmpty);
    expect(registry.read<StorageMigrator>().targetVersion, 1);
    expect(registry.read<StorageSupport>(), isA<StorageSupport>());
  });
}
