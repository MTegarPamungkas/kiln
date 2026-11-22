import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/local_db/backup_export.dart';

import 'test_support.dart';

void main() {
  test('restores a write that mutated before throwing', () async {
    final target = await openTestDatabase();
    await target.put('tasks', 'existing', {'title': 'before'});
    final failing = _FailingDatabase(target);
    await expectLater(
      const BackupExport().import(
        database: failing,
        backup: {
          'version': 1,
          'collections': {
            'tasks': [
              {
                'key': 'existing',
                'data': {'title': 'after'},
              },
              {
                'key': 'new',
                'data': {'title': 'new'},
              },
            ],
          },
        },
      ),
      throwsStateError,
    );
    expect(await target.get('tasks', 'existing'), {'title': 'before'});
    expect(await target.get('tasks', 'new'), isNull);
    await target.close();
  });

  test('reports compensation failure explicitly', () async {
    final target = await openTestDatabase();
    final failing = _FailingDatabase(target)..failRollback = true;
    await expectLater(
      const BackupExport().import(
        database: failing,
        backup: {
          'version': 1,
          'collections': {
            'tasks': [
              {
                'key': 'new',
                'data': {'title': 'new'},
              },
            ],
          },
        },
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.details['rollbackFailed'],
          'rollbackFailed',
          true,
        ),
      ),
    );
    await target.close();
  });

  test('rejects nested non-string keys before writing', () async {
    final target = await openTestDatabase();
    await expectLater(
      const BackupExport().import(
        database: target,
        backup: {
          'version': 1,
          'collections': {
            'tasks': [
              {
                'key': 'valid',
                'data': {'title': 'valid'},
              },
              {
                'key': 'bad',
                'data': {
                  'nested': {1: 'invalid'},
                },
              },
            ],
          },
        },
      ),
      throwsA(isA<Failure>()),
    );
    expect(await target.query('tasks'), isEmpty);
    await target.close();
  });

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

  test('rejects an unsupported backup version before writing', () async {
    final target = await openTestDatabase();
    await target.put('tasks', 'keep', {'title': 'existing'});

    await expectLater(
      const BackupExport().import(
        database: target,
        backup: <String, Object?>{
          'version': 99,
          'collections': <String, Object?>{
            'tasks': <Object?>[
              <String, Object?>{'key': '1', 'data': <String, Object?>{}},
            ],
          },
        },
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationUnsupportedValue,
        ),
      ),
    );

    expect(await target.get('tasks', '1'), isNull);
    expect(await target.get('tasks', 'keep'), {'title': 'existing'});
    await target.close();
  });

  test('a malformed record fails before any collection is written', () async {
    final target = await openTestDatabase();

    await expectLater(
      const BackupExport().import(
        database: target,
        backup: <String, Object?>{
          'version': 1,
          'collections': <String, Object?>{
            'tasks': <Object?>[
              <String, Object?>{'key': 'valid', 'data': <String, Object?>{}},
              'not-a-record',
            ],
          },
        },
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );

    expect(await target.get('tasks', 'valid'), isNull);
    await target.close();
  });

  test('clears the journal after a successful import', () async {
    final target = await openTestDatabase();
    await const BackupExport().import(
      database: target,
      backup: <String, Object?>{
        'version': 1,
        'collections': <String, Object?>{
          'tasks': <Object?>[
            <String, Object?>{'key': '1', 'data': <String, Object?>{}},
          ],
        },
      },
    );

    expect(await target.query('_kiln_import_journal'), isEmpty);
    await target.close();
  });

  test('rejects a backup that writes into the journal', () async {
    final target = await openTestDatabase();

    await expectLater(
      const BackupExport().import(
        database: target,
        backup: <String, Object?>{
          'version': 1,
          'collections': <String, Object?>{
            '_kiln_import_journal': <Object?>[
              <String, Object?>{'key': 'x', 'data': <String, Object?>{}},
            ],
          },
        },
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    await target.close();
  });

  test('rolls back an import interrupted by a process death', () async {
    final target = await openTestDatabase();
    await target.put('tasks', 'existing', <String, Object?>{'title': 'before'});
    await target.put('tasks', 'touched', <String, Object?>{'title': 'before'});
    // A crashed import: the journal says active, one record was overwritten and
    // one was created before the process died.
    await target.put('tasks', 'touched', <String, Object?>{'title': 'after'});
    await target.put('tasks', 'created', <String, Object?>{'title': 'new'});
    await target.put('_kiln_import_journal', '__status__', <String, Object?>{
      'active': true,
      'at': '2026-11-20T00:00:00Z',
    });
    await target.put('_kiln_import_journal', '00000000', <String, Object?>{
      'collection': 'tasks',
      'key': 'touched',
      'previous': <String, Object?>{'title': 'before'},
    });
    await target.put('_kiln_import_journal', '00000001', <String, Object?>{
      'collection': 'tasks',
      'key': 'created',
      'previous': null,
    });

    expect(await const BackupExport().recover(database: target), isTrue);

    expect(await target.get('tasks', 'touched'), {'title': 'before'});
    expect(await target.get('tasks', 'created'), isNull);
    expect(await target.get('tasks', 'existing'), {'title': 'before'});
    expect(await target.query('_kiln_import_journal'), isEmpty);
    // Running recovery again is a no-op.
    expect(await const BackupExport().recover(database: target), isFalse);
    await target.close();
  });

  test('keeps data from a committed journal and only clears it', () async {
    final target = await openTestDatabase();
    await target.put('tasks', 'kept', <String, Object?>{'title': 'imported'});
    await target.put('_kiln_import_journal', '__status__', <String, Object?>{
      'active': false,
      'at': '2026-11-20T00:00:00Z',
    });
    await target.put('_kiln_import_journal', '00000000', <String, Object?>{
      'collection': 'tasks',
      'key': 'kept',
      'previous': <String, Object?>{'title': 'before'},
    });

    expect(await const BackupExport().recover(database: target), isFalse);

    expect(await target.get('tasks', 'kept'), {'title': 'imported'});
    expect(await target.query('_kiln_import_journal'), isEmpty);
    await target.close();
  });

  test('an import first rolls back a previous interrupted import', () async {
    final target = await openTestDatabase();
    await target.put('tasks', 'touched', <String, Object?>{'title': 'partial'});
    await target.put('_kiln_import_journal', '__status__', <String, Object?>{
      'active': true,
      'at': '2026-11-20T00:00:00Z',
    });
    await target.put('_kiln_import_journal', '00000000', <String, Object?>{
      'collection': 'tasks',
      'key': 'touched',
      'previous': <String, Object?>{'title': 'before'},
    });

    await const BackupExport().import(
      database: target,
      backup: <String, Object?>{
        'version': 1,
        'collections': <String, Object?>{
          'tasks': <Object?>[
            <String, Object?>{
              'key': 'touched',
              'data': <String, Object?>{'title': 'imported'},
            },
          ],
        },
      },
    );

    expect(await target.get('tasks', 'touched'), {'title': 'imported'});
    expect(await target.query('_kiln_import_journal'), isEmpty);
    await target.close();
  });
}

final class _FailingDatabase implements LocalDatabase {
  _FailingDatabase(this.inner);
  final LocalDatabase inner;
  bool failRollback = false;
  bool _failed = false;

  @override
  Future<void> put(
    String collection,
    String key,
    Map<String, Object?> data,
  ) async {
    await inner.put(collection, key, data);
    if (!_failed && key == 'new') {
      _failed = true;
      throw StateError('write acknowledgement failed');
    }
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String key) =>
      inner.get(collection, key);

  @override
  Future<void> delete(String collection, String key) {
    if (failRollback) throw StateError('rollback failed');
    return inner.delete(collection, key);
  }

  @override
  Future<List<LocalRecord>> query(String collection, {LocalQuery? query}) =>
      inner.query(collection, query: query);

  @override
  Stream<List<LocalRecord>> watch(String collection, {LocalQuery? query}) =>
      inner.watch(collection, query: query);

  @override
  Future<void> close() => inner.close();
}
