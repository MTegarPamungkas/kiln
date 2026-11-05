import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('Android manifest patches', () {
    late Directory project;
    late ProjectFiles files;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      files = ProjectFiles(project);
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('adds a permission once and reverts it', () {
      const patch = AndroidPermissionPatch('android.permission.INTERNET');

      patch.apply(files);
      patch.apply(files);
      final content = files.read(kAndroidManifestPath)!;

      expect(
        RegExp('android.permission.INTERNET').allMatches(content),
        hasLength(1),
      );

      patch.revert(files);
      expect(files.read(kAndroidManifestPath), isNot(contains('INTERNET')));
    });

    test('adds and reverts a custom URL scheme', () {
      const patch = AndroidUrlSchemePatch('kiln');

      patch.apply(files);
      final content = files.read(kAndroidManifestPath)!;
      expect(content, contains('android:scheme="kiln"'));
      expect(content, contains('android.intent.category.BROWSABLE'));

      patch.revert(files);
      expect(files.read(kAndroidManifestPath), isNot(contains('kiln')));
    });

    test('adds and reverts an App Link with path prefixes', () {
      const patch = AndroidAppLinkPatch('kiln.dev', pathPrefixes: ['/profile']);

      patch.apply(files);
      final content = files.read(kAndroidManifestPath)!;
      expect(content, contains('android:autoVerify="true"'));
      expect(content, contains('android:host="kiln.dev"'));
      expect(content, contains('android:pathPrefix="/profile"'));

      patch.revert(files);
      expect(files.read(kAndroidManifestPath), isNot(contains('kiln.dev')));
    });

    test('sets allowBackup and removes it on revert', () {
      const patch = AndroidAllowBackupPatch(false);

      patch.apply(files);
      expect(
        files.read(kAndroidManifestPath),
        contains('android:allowBackup="false"'),
      );

      patch.revert(files);
      expect(files.read(kAndroidManifestPath), isNot(contains('allowBackup')));
    });
  });
}
