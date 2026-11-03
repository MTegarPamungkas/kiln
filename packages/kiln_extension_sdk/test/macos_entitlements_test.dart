import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('MacosEntitlementPatch', () {
    late Directory project;
    late ProjectFiles files;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      files = ProjectFiles(project);
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('adds one entitlement to both files', () {
      const patch = MacosEntitlementPatch(
        'com.apple.security.network.client',
        true,
      );

      patch.apply(files);

      for (final path in kMacosEntitlementsPaths) {
        final content = files.read(path)!;
        expect(
          content,
          contains('<key>com.apple.security.network.client</key>'),
        );
        expect(content, contains('<true/>'));
      }
    });

    test('reverts the entitlement from both files', () {
      const patch = MacosEntitlementPatch(
        'com.apple.security.network.client',
        true,
      );
      patch.apply(files);
      patch.revert(files);

      for (final path in kMacosEntitlementsPaths) {
        expect(files.read(path), isNot(contains('network.client')));
      }
    });
  });
}
