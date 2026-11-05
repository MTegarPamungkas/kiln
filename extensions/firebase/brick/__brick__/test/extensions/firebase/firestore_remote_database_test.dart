import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/firebase/firestore_gateway.dart';
import 'package:{{app_name}}/extensions/firebase/firestore_remote_database.dart';

import 'firebase_contract_test.dart';

void main() {
  test('create, read, update, and delete round-trip', () async {
    final gateway = InMemoryFirestoreGateway();
    final database = FirestoreRemoteDatabase(gateway: gateway);

    final created = await database.create('users', {'name': 'Tegar'});
    final id = '${created['id']}';
    expect(created['name'], 'Tegar');
    expect(created['id'], isNotNull);

    expect((await database.read('users', id))?['name'], 'Tegar');

    final updated = await database.update('users', id, {'name': 'Tegar P'});
    expect(updated['id'], id);
    expect(updated['name'], 'Tegar P');

    await database.delete('users', id);
    expect(await database.read('users', id), isNull);
  });

  test('an empty collection or id is a validation Failure', () async {
    final database = FirestoreRemoteDatabase(
      gateway: InMemoryFirestoreGateway(),
    );

    await expectLater(
      database.create(' ', {'name': 'Nobody'}),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    await expectLater(database.read('users', ''), throwsA(isA<Failure>()));
  });

  test('query maps RemoteQuery before calling Firestore', () async {
    final gateway = InMemoryFirestoreGateway();
    final database = FirestoreRemoteDatabase(gateway: gateway);
    await database.create('tasks', {'title': 'one', 'done': false});
    await database.create('tasks', {'title': 'two', 'done': true});
    await database.create('tasks', {'title': 'three', 'done': true});

    final documents = await database.query(
      'tasks',
      query: const RemoteQuery(
        filters: [RemoteFilter('done', RemoteFilterOperator.equals, true)],
        orderBy: [RemoteOrder('title')],
        limit: 1,
        offset: 1,
      ),
    );

    expect(gateway.queries, hasLength(1));
    final mapped = gateway.queries.single;
    expect(mapped.filters.single.field, 'done');
    expect(mapped.filters.single.operator, FirestoreFilterOperator.equal);
    expect(mapped.orders.single.field, 'title');
    expect(mapped.limit, 1);
    expect(mapped.offset, 1);
    expect(documents.map((document) => document['title']), ['two']);
  });

  test('unsupported queries fail before touching the gateway', () async {
    final gateway = InMemoryFirestoreGateway();
    final database = FirestoreRemoteDatabase(gateway: gateway);

    await expectLater(
      database.query(
        'tasks',
        query: const RemoteQuery(
          filters: [
            RemoteFilter('done', RemoteFilterOperator.equals, true),
            RemoteFilter('score', RemoteFilterOperator.greaterThan, 10),
            RemoteFilter('rank', RemoteFilterOperator.lessThan, 3),
          ],
        ),
      ),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationUnsupportedValue,
        ),
      ),
    );
    expect(gateway.queries, isEmpty);
  });

  test('missing documents cannot be updated or deleted', () async {
    final database = FirestoreRemoteDatabase(
      gateway: InMemoryFirestoreGateway(),
    );

    await expectLater(
      database.update('users', 'missing', {'name': 'Nobody'}),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.remoteDatabaseNotFound,
        ),
      ),
    );
    await expectLater(
      database.delete('users', 'missing'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.remoteDatabaseNotFound,
        ),
      ),
    );
  });

  test('watch emits the current document and later updates', () async {
    final database = FirestoreRemoteDatabase(
      gateway: InMemoryFirestoreGateway(),
    );
    final created = await database.create('users', {'name': 'First'});
    final id = '${created['id']}';
    final seen = <Map<String, Object?>?>[];
    final subscription = database.watch('users', id).listen(seen.add);

    await Future<void>.delayed(Duration.zero);
    expect(seen.last?['name'], 'First');

    await database.update('users', id, {'name': 'Second'});
    expect(seen.last?['name'], 'Second');

    await subscription.cancel();
    await database.update('users', id, {'name': 'Third'});
    expect(seen.last?['name'], 'Second');
  });

  test('gateway errors are mapped to RemoteDatabase Failures', () async {
    final gateway = InMemoryFirestoreGateway()
      ..error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    final database = FirestoreRemoteDatabase(gateway: gateway);

    await expectLater(
      database.read('users', 'any'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.authUnauthorized,
        ),
      ),
    );
  });
}
