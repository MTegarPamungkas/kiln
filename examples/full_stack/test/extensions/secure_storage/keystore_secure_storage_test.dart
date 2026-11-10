import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('stores secrets under the app prefix', () async {
    final gateway = FakeSecureStorageGateway()..values['other.key'] = 'keep';
    final storage = createTestSecureStorage(gateway: gateway);

    await storage.write('token', 'secret');

    expect(gateway.values['app.token'], 'secret');
    expect(await storage.read('token'), 'secret');
    expect(await storage.readAll(), {'token': 'secret'});

    await storage.clear();
    expect(await storage.read('token'), isNull);
    expect(gateway.values['other.key'], 'keep');
  });

  test('maps gateway errors to Failure', () async {
    final gateway = FakeSecureStorageGateway()..failReads = true;
    final storage = createTestSecureStorage(gateway: gateway);

    await expectLater(
      storage.read('token'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.secureStorageReadFailed,
        ),
      ),
    );
  });

  test('maps delete errors to a write failure', () async {
    final gateway = FakeSecureStorageGateway()..failDeletes = true;
    final storage = createTestSecureStorage(gateway: gateway);

    await expectLater(
      storage.delete('token'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.secureStorageWriteFailed,
        ),
      ),
    );
  });
}
