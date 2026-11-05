import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef StorageContractFactory = FutureOr<Storage> Function();

/// Behavior every [Storage] implementation must share.
void storageContract({
  required StorageContractFactory create,
  String description = 'Storage',
}) {
  group('$description contract', () {
    test('a missing key reads null', () async {
      final storage = await create();

      expect(await storage.read('missing'), isNull);
      expect(await storage.containsKey('missing'), isFalse);
    });

    test('write, read, overwrite, and delete round-trip', () async {
      final storage = await create();

      await storage.write('name', 'kiln');
      expect(await storage.read('name'), 'kiln');
      expect(await storage.containsKey('name'), isTrue);

      await storage.write('name', 'kiln-cli');
      expect(await storage.read('name'), 'kiln-cli');

      await storage.delete('name');
      expect(await storage.read('name'), isNull);
      expect(await storage.containsKey('name'), isFalse);
    });

    test('keys lists only existing keys and clear removes them all', () async {
      final storage = await create();

      await storage.write('a', '1');
      await storage.write('b', '2');
      expect(await storage.keys(), containsAll(<String>['a', 'b']));

      await storage.clear();
      expect(await storage.keys(), isEmpty);
      expect(await storage.read('a'), isNull);
    });
  });
}
