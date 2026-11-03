import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('WebIndexMetaPatch', () {
    late Directory project;
    late ProjectFiles files;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      files = ProjectFiles(project);
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('adds a marker before the head close tag', () {
      const patch = WebIndexMetaPatch('dio');

      patch.apply(files);
      final content = files.read(kWebIndexPath)!;
      expect(content, contains('name="kiln-extension:dio"'));
      expect(
        content.indexOf('kiln-extension:dio'),
        lessThan(content.indexOf('</head>')),
      );

      patch.revert(files);
      expect(files.read(kWebIndexPath), isNot(contains('kiln-extension:dio')));
    });

    test('is idempotent', () {
      const patch = WebIndexMetaPatch('dio');
      patch.apply(files);
      patch.apply(files);

      expect(
        RegExp('kiln-extension:dio').allMatches(files.read(kWebIndexPath)!),
        hasLength(1),
      );
    });
  });
}
