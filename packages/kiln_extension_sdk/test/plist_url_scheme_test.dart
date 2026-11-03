import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('Plist URL scheme patches', () {
    late Directory project;
    late ProjectFiles files;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      files = ProjectFiles(project);
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('adds iOS scheme once and reverts the whole entry', () {
      const patch = IosUrlSchemePatch('kiln');

      patch.apply(files);
      patch.apply(files);
      final content = files.read(kIosInfoPlistPath)!;

      expect(RegExp('<string>kiln</string>').allMatches(content), hasLength(1));
      expect(content, contains('<key>CFBundleURLTypes</key>'));

      patch.revert(files);
      final reverted = files.read(kIosInfoPlistPath)!;
      expect(reverted, isNot(contains('<string>kiln</string>')));
      expect(reverted, isNot(contains('<key>CFBundleURLTypes</key>')));
    });

    test('reverting one macOS scheme keeps the other scheme', () {
      const kiln = MacosUrlSchemePatch('kiln');
      const auth = MacosUrlSchemePatch('kiln-auth');

      kiln.apply(files);
      auth.apply(files);
      final both = files.read(kMacosInfoPlistPath)!;
      expect(both, contains('<string>kiln</string>'));
      expect(both, contains('<string>kiln-auth</string>'));

      kiln.revert(files);
      final remaining = files.read(kMacosInfoPlistPath)!;
      expect(remaining, isNot(contains('<string>kiln</string>')));
      expect(remaining, contains('<string>kiln-auth</string>'));
      expect(remaining, contains('<key>CFBundleURLTypes</key>'));

      auth.revert(files);
      final empty = files.read(kMacosInfoPlistPath)!;
      expect(empty, isNot(contains('<string>kiln-auth</string>')));
      expect(empty, isNot(contains('<key>CFBundleURLTypes</key>')));
    });

    test('ignores an unrelated plist string with the same value', () {
      const path = 'ios/Runner/Info.plist';
      final plist = files.read(path)!;
      files.write(
        path,
        plist.replaceFirst(
          '<dict>',
          '<dict>\n  <key>Unrelated</key>\n  <string>kiln</string>',
        ),
      );
      const patch = IosUrlSchemePatch('kiln');

      patch.apply(files);
      final content = files.read(path)!;

      expect(content, contains('<key>CFBundleURLTypes</key>'));
      expect(RegExp('<string>kiln</string>').allMatches(content), hasLength(2));

      patch.revert(files);
      final reverted = files.read(path)!;
      expect(reverted, contains('<key>Unrelated</key>'));
      expect(
        RegExp('<string>kiln</string>').allMatches(reverted),
        hasLength(1),
      );
    });
  });
}
