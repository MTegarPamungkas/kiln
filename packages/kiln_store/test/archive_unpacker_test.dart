import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const unpacker = ArchiveUnpacker();
  final fixtureRoot = Directory(
    p.join(Directory.current.path, 'test', 'fixtures', 'registry'),
  );
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('kiln_store_unpack_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  group('ArchiveUnpacker', () {
    test('extracts a valid registry archive', () {
      final target = Directory(p.join(temp.path, 'extension'));
      final bytes = File(p.join(fixtureRoot.path, 'valid.tgz'))
          .readAsBytesSync();

      unpacker.extract(bytes, target);

      expect(
        File(p.join(target.path, 'extension.yaml')).readAsStringSync(),
        contains('id: demo_ext'),
      );
      expect(
        File(p.join(target.path, 'brick', 'brick.yaml')).existsSync(),
        isTrue,
      );
    });

    test('rejects the zip-slip fixture and writes nothing', () {
      final target = Directory(p.join(temp.path, 'extension'));
      final bytes = File(p.join(fixtureRoot.path, 'zip-slip.tgz'))
          .readAsBytesSync();

      expect(
        () => unpacker.extract(bytes, target),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.unsafe_archive',
          ),
        ),
      );
      expect(File(p.join(temp.path, 'evil.txt')).existsSync(), isFalse);
      expect(target.existsSync(), isFalse);
    });

    test('rejects absolute, drive-letter, and traversal paths', () {
      for (final name in <String>[
        '/evil.txt',
        'C:/evil.txt',
        'C:\\evil.txt',
        '../evil.txt',
        'dir/../../evil.txt',
        'dir/../evil.txt',
        '..\\evil.txt',
        'dir//evil.txt',
      ]) {
        final archive = Archive()
          ..add(ArchiveFile.bytes(name, utf8.encode('pwned')));
        final target = Directory(p.join(temp.path, 'target'));

        expect(
          () => unpacker.extract(_tgz(archive), target),
          throwsA(
            isA<KilnStoreException>().having(
              (error) => error.code,
              'code',
              'store.unsafe_archive',
            ),
          ),
          reason: 'entry "$name" should be rejected',
        );
        expect(target.existsSync(), isFalse);
      }
    });

    test('rejects symbolic links', () {
      final archive = Archive()
        ..add(ArchiveFile.symlink('link.yaml', '../evil.yaml'));

      expect(
        () => unpacker.extract(
          _tgz(archive),
          Directory(p.join(temp.path, 'target')),
        ),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.unsafe_archive',
          ),
        ),
      );
    });

    test('rejects hard links', () {
      final archive = Archive()
        ..add(
          ArchiveFile.symlink('hard.yaml', 'extension.yaml')..isHardLink = true,
        );

      expect(
        () => unpacker.extract(
          _tgz(archive),
          Directory(p.join(temp.path, 'target')),
        ),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.unsafe_archive',
          ),
        ),
      );
    });

    test('extracts explicit directory entries', () {
      final archive = Archive()
        ..add(ArchiveFile.directory('assets'))
        ..add(ArchiveFile.bytes('assets/logo.txt', utf8.encode('logo')));
      final target = Directory(p.join(temp.path, 'target'));

      unpacker.extract(_tgz(archive), target);

      expect(
        File(p.join(target.path, 'assets', 'logo.txt')).readAsStringSync(),
        'logo',
      );
    });

    test('rejects data that is not a tar.gz archive', () {
      expect(
        () => unpacker.extract(
          utf8.encode('not an archive'),
          Directory(p.join(temp.path, 'target')),
        ),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.invalid_archive',
          ),
        ),
      );
    });
  });
}

List<int> _tgz(Archive archive) {
  return GZipEncoder().encodeBytes(TarEncoder().encodeBytes(archive));
}
