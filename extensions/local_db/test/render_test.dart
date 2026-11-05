import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('local_db brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'local_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/local_db/local_db_module.dart',
        'lib/extensions/local_db/sembast_local_database.dart',
        'lib/extensions/local_db/query_builder.dart',
        'lib/extensions/local_db/collection_watcher.dart',
        'lib/extensions/local_db/transaction_runner.dart',
        'lib/extensions/local_db/backup_export.dart',
        'lib/extensions/local_db/sync_queue.dart',
        'lib/extensions/local_db/database_encryption.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('local_db_config.dart'),
    );
    expect(String.fromCharCodes(config.bytes), contains('local_app.db'));
  });
}
