import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('IosPodfilePermissionPatch', () {
    late Directory project;
    late ProjectFiles files;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      files = ProjectFiles(project);
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('adds a permission flag after the platform line', () {
      const patch = IosPodfilePermissionPatch('camera');

      patch.apply(files);
      final content = files.read(kIosPodfilePath)!;

      expect(content, contains('PERMISSION_CAMERA = 1'));
      expect(
        content.indexOf('PERMISSION_CAMERA'),
        greaterThan(content.indexOf('platform :ios')),
      );
      expect(content, contains("platform :ios, '13.0'"));
    });

    test('is idempotent and revert removes every permission flag', () {
      const camera = IosPodfilePermissionPatch('camera');
      const photos = IosPodfilePermissionPatch('photos');

      camera.apply(files);
      camera.apply(files);
      photos.apply(files);
      expect(
        RegExp('PERMISSION_CAMERA').allMatches(files.read(kIosPodfilePath)!),
        hasLength(1),
      );

      camera.revert(files);
      expect(files.read(kIosPodfilePath), isNot(contains('PERMISSION_')));
    });
  });
}
