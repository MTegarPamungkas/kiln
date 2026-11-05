import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef BatchRemoteDatabaseContractFactory =
    FutureOr<BatchRemoteDatabase> Function();

/// Behavior every [BatchRemoteDatabase] implementation must share.
void batchRemoteDatabaseContract({
  required BatchRemoteDatabaseContractFactory create,
  String description = 'BatchRemoteDatabase',
}) {
  group('$description contract', () {
    test('writeBatch applies insert, update, and delete together', () async {
      final database = await create();
      final kept = await database.create('users', {'name': 'Keep'});
      final removed = await database.create('users', {'name': 'Remove'});

      await database.writeBatch('users', <RemoteWrite>[
        const RemoteWrite.insert({'name': 'Added'}),
        RemoteWrite.update('${kept['id']}', {'name': 'Renamed'}),
        RemoteWrite.delete('${removed['id']}'),
      ]);

      expect(
        (await database.read('users', '${kept['id']}'))?['name'],
        'Renamed',
      );
      expect(await database.read('users', '${removed['id']}'), isNull);
      expect(await database.query('users'), hasLength(2));
    });

    test('createMany inserts every document', () async {
      final database = await create();

      final created = await database.createMany('tasks', [
        {'title': 'one'},
        {'title': 'two'},
      ]);

      expect(created, hasLength(2));
      final all = await database.query('tasks');
      expect(all, hasLength(2));
      expect(all.map((document) => document['title']).toSet(), {'one', 'two'});
    });

    test('updateMany patches each document', () async {
      final database = await create();
      final first = await database.create('users', {'name': 'A'});
      final second = await database.create('users', {'name': 'B'});

      await database.updateMany('users', {
        '${first['id']}': {'name': 'AA'},
        '${second['id']}': {'name': 'BB'},
      });

      expect((await database.read('users', '${first['id']}'))?['name'], 'AA');
      expect((await database.read('users', '${second['id']}'))?['name'], 'BB');
    });

    test('deleteMany removes each document', () async {
      final database = await create();
      final first = await database.create('users', {'name': 'A'});
      final second = await database.create('users', {'name': 'B'});

      await database.deleteMany('users', ['${first['id']}', '${second['id']}']);

      expect(await database.read('users', '${first['id']}'), isNull);
      expect(await database.read('users', '${second['id']}'), isNull);
    });
  });
}
