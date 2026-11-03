import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/local_db/local_database_support.dart';
import 'package:{{app_name}}/extensions/local_db/local_db_config.dart';
import 'package:{{app_name}}/extensions/local_db/local_db_module.dart';

void main() {
  test('module registers LocalDatabase and config', () {
    final registry = GetItRegistry();

    const LocalDbModule().register(registry);

    expect(registry.read<LocalDatabase>(), isA<LocalDatabase>());
    expect(registry.read<LocalDbConfig>().databaseName, isNotEmpty);
    expect(registry.read<LocalDatabaseSupport>(), isA<LocalDatabaseSupport>());
  });
}
