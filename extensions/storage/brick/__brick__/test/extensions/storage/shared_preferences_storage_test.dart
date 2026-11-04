import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('stores values under the app prefix', () async {
    final gateway = FakeStorageGateway()
      ..values['other.key'] = 'keep';
    final storage = createTestStorage(gateway: gateway);

    await storage.write('name', 'kiln');

    expect(gateway.values['app.name'], 'kiln');
    expect(await storage.read('name'), 'kiln');
    expect(await storage.keys(), {'name'});
    expect(await storage.containsKey('name'), isTrue);

    await storage.clear();
    expect(await storage.read('name'), isNull);
    expect(gateway.values['other.key'], 'keep');
  });

  test('maps gateway errors to Failure', () async {
    final gateway = FakeStorageGateway()..failReads = true;
    final storage = createTestStorage(gateway: gateway);

    await expectLater(
      storage.read('name'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.storageReadFailed,
        ),
      ),
    );
  });

  test('maps delete errors to a write failure', () async {
    final gateway = FakeStorageGateway()..failDeletes = true;
    final storage = createTestStorage(gateway: gateway);

    await expectLater(
      storage.delete('name'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.storageWriteFailed,
        ),
      ),
    );
  });
}
