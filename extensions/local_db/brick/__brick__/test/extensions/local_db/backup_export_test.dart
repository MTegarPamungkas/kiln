import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/local_db/backup_export.dart';

import 'test_support.dart';

void main() {
  test('exports and imports collections', () async {
    final source = await openTestDatabase();
    await source.put('tasks', '1', {'title': 'one'});
    await source.put('tasks', '2', {'title': 'two'});

    final backup = await const BackupExport().export(
      database: source,
      collections: const ['tasks'],
    );

    final target = await openTestDatabase();
    await const BackupExport().import(database: target, backup: backup);

    expect(await target.get('tasks', '1'), {'title': 'one'});
    expect(await target.get('tasks', '2'), {'title': 'two'});
    await source.close();
    await target.close();
  });
}
