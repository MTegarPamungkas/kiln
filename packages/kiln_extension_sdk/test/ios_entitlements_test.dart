import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('iOS plist and entitlement patches', () {
    late Directory project;
    late ProjectFiles files;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      files = ProjectFiles(project);
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('adds an Info.plist key and removes it', () {
      const patch = IosPlistKeyPatch(
        'NSFaceIDUsageDescription',
        'Unlock the app',
      );

      patch.apply(files);
      expect(
        files.read(kIosInfoPlistPath),
        contains('<key>NSFaceIDUsageDescription</key>'),
      );

      patch.revert(files);
      expect(
        files.read(kIosInfoPlistPath),
        isNot(contains('NSFaceIDUsageDescription')),
      );
    });

    test('adds a custom URL scheme', () {
      const patch = IosUrlSchemePatch('kiln');

      patch.apply(files);
      final content = files.read(kIosInfoPlistPath)!;
      expect(content, contains('<key>CFBundleURLTypes</key>'));
      expect(content, contains('<string>kiln</string>'));

      patch.revert(files);
      expect(
        files.read(kIosInfoPlistPath),
        isNot(contains('<string>kiln</string>')),
      );
    });

    test('adds an entitlement', () {
      const patch = IosEntitlementPatch('com.apple.developer.applesignin', [
        'Default',
      ]);

      patch.apply(files);
      final content = files.read(kIosEntitlementsPath)!;
      expect(content, contains('<key>com.apple.developer.applesignin</key>'));
      expect(content, contains('<string>Default</string>'));

      patch.revert(files);
      expect(files.read(kIosEntitlementsPath), isNot(contains('applesignin')));
    });

    test('merges associated domains under one key', () {
      final first = const IosAssociatedDomainPatch('kiln.dev');
      const second = IosAssociatedDomainPatch('app.kiln.dev');

      first.apply(files);
      second.apply(files);
      final content = files.read(kIosEntitlementsPath)!;

      expect(
        RegExp('com.apple.developer.associated-domains').allMatches(content),
        hasLength(1),
      );
      expect(content, contains('<string>applinks:kiln.dev</string>'));
      expect(content, contains('<string>applinks:app.kiln.dev</string>'));

      first.revert(files);
      second.revert(files);
      expect(files.read(kIosEntitlementsPath), isNot(contains('applinks:')));
    });

    test('adds the AppDelegate URL handler once', () {
      const patch = IosAppDelegatePatch();

      patch.apply(files);
      patch.apply(files);
      final content = files.read(kIosAppDelegatePath)!;
      expect(content, contains('// kiln:url-schemes'));
      expect(RegExp('kiln:url-schemes').allMatches(content), hasLength(1));

      patch.revert(files);
      expect(
        files.read(kIosAppDelegatePath),
        isNot(contains('kiln:url-schemes')),
      );
    });
  });
}
