import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  const ownership = FileOwnership();

  group('FileOwnership', () {
    test('hashes bytes deterministically', () {
      final first = ownership.hashBytes([1, 2, 3]);
      final second = ownership.hashBytes([1, 2, 3]);
      final different = ownership.hashBytes([1, 2, 4]);

      expect(first, second);
      expect(first, isNot(different));
      expect(first, startsWith('sha256:'));
      expect(first.substring(7), hasLength(64));
    });

    test('detects a file changed since it was owned', () async {
      final temp = await Directory.systemTemp.createTemp('kiln_owner_');
      final file = File('${temp.path}/file.txt');
      await file.writeAsString('original');
      final hash = ownership.hashFile(file);

      expect(ownership.hasChanged(file: file, ownedHash: hash), isFalse);

      await file.writeAsString('edited');
      expect(ownership.hasChanged(file: file, ownedHash: hash), isTrue);

      await file.delete();
      expect(ownership.hasChanged(file: file, ownedHash: hash), isTrue);
      await temp.delete(recursive: true);
    });

    test('treats an empty or missing hash as changed', () async {
      final temp = await Directory.systemTemp.createTemp('kiln_owner_');
      final file = File('${temp.path}/file.txt');
      await file.writeAsString('content');

      expect(ownership.hasChanged(file: file, ownedHash: null), isTrue);
      expect(ownership.hasChanged(file: file, ownedHash: ''), isTrue);
      await temp.delete(recursive: true);
    });
  });
}
