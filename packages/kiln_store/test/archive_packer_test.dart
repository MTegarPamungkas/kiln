import 'dart:io';

import 'package:archive/archive.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const packer = ArchivePacker();
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('kiln_store_pack_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  group('ArchivePacker', () {
    test('packs extension files with relative POSIX paths', () {
      final root = _createExtension(temp);

      final names = _entryNames(packer.pack(root));

      expect(names, [
        'brick/brick.yaml',
        'extension.yaml',
        'lib/demo_module.dart',
      ]);
      expect(names.every((name) => !name.contains('\\')), isTrue);
    });

    test('skips tool, VCS, build, and generated archive directories', () {
      final root = _createExtension(temp);
      _write(root, '.dart_tool/package_config.json', '{}');
      _write(root, '.git/config', 'git');
      _write(root, 'build/output.txt', 'build');
      _write(root, '.kiln/cache.txt', 'cache');
      _write(root, 'lib/build/generated.dart', 'generated');
      _write(root, 'demo_ext-1.0.0.tgz', 'archive');
      _write(root, 'dist/demo.tar.gz', 'archive');

      final names = _entryNames(packer.pack(root));

      expect(names, [
        'brick/brick.yaml',
        'extension.yaml',
        'lib/demo_module.dart',
      ]);
    });

    test('is deterministic for the same tree', () {
      final root = _createExtension(temp);

      final first = packer.pack(root);
      final second = packer.pack(root);

      expect(first, equals(second));
    });

    test('round-trips through ArchiveUnpacker', () {
      final root = _createExtension(temp);
      final target = Directory(p.join(temp.path, 'unpacked'));

      const ArchiveUnpacker().extract(packer.pack(root), target);

      expect(
        File(p.join(target.path, 'extension.yaml')).readAsStringSync(),
        contains('id: demo_ext'),
      );
      expect(
        File(p.join(target.path, 'brick', 'brick.yaml')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(target.path, 'lib', 'demo_module.dart')).readAsStringSync(),
        'module',
      );
    });

    test('throws when the extension root does not exist', () {
      expect(
        () => packer.pack(Directory(p.join(temp.path, 'missing'))),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.pack_missing_root',
          ),
        ),
      );
    });

    test('packs an empty directory as a valid empty archive', () {
      final root = Directory(p.join(temp.path, 'empty'))
        ..createSync(recursive: true);

      final bytes = packer.pack(root);
      final archive = TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(bytes),
        verify: true,
      );

      expect(archive.files, isEmpty);
    });
  });
}

Directory _createExtension(Directory temp) {
  final root = Directory(p.join(temp.path, 'demo_ext'))..createSync();
  _write(
    root,
    'extension.yaml',
    'id: demo_ext\n'
        'name: Demo\n'
        'version: 1.0.0\n'
        'description: Demo\n'
        'category: testing\n',
  );
  _write(root, 'brick/brick.yaml', 'name: demo_ext\n');
  _write(root, 'lib/demo_module.dart', 'module');
  return root;
}

void _write(Directory root, String relative, String content) {
  final file = File(p.joinAll(<String>[root.path, ...relative.split('/')]));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

List<String> _entryNames(List<int> bytes) {
  final archive = TarDecoder().decodeBytes(
    GZipDecoder().decodeBytes(bytes),
    verify: true,
  );
  return archive.files.map((entry) => entry.name).toList(growable: false)
    ..sort();
}
