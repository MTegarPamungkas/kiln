import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef SecureStorageContractFactory = FutureOr<SecureStorage> Function();

/// Behavior every [SecureStorage] implementation must share.
void secureStorageContract({
  required SecureStorageContractFactory create,
  String description = 'SecureStorage',
}) {
  group('$description contract', () {
    test('a missing secret reads null', () async {
      final storage = await create();

      expect(await storage.read('missing'), isNull);
    });

    test('write, read, overwrite, and delete round-trip', () async {
      final storage = await create();

      await storage.write('token', 'one');
      expect(await storage.read('token'), 'one');

      await storage.write('token', 'two');
      expect(await storage.read('token'), 'two');

      await storage.delete('token');
      expect(await storage.read('token'), isNull);
    });

    test('readAll returns every stored secret', () async {
      final storage = await create();

      await storage.write('access', 'a');
      await storage.write('refresh', 'b');

      final all = await storage.readAll();
      expect(all, containsPair('access', 'a'));
      expect(all, containsPair('refresh', 'b'));
    });

    test('clear removes every secret', () async {
      final storage = await create();

      await storage.write('access', 'a');
      await storage.clear();

      expect(await storage.readAll(), isEmpty);
    });
  });
}
