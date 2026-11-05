import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('NativeSetup', () {
    late Directory project;
    late AvailableExtension extension;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      extension = makeExtension(
        id: 'demo',
        platformSetup: const PlatformSetup(
          android: AndroidSetup(
            permissions: ['android.permission.INTERNET'],
            urlSchemes: ['kiln'],
            receivers: [
              AndroidReceiverSetup(
                name: 'com.example.BootReceiver',
                actions: ['android.intent.action.BOOT_COMPLETED'],
              ),
            ],
            minSdk: 24,
            compileSdk: 37,
          ),
          ios: IosSetup(
            plist: {'NSFaceIDUsageDescription': 'Unlock'},
            podfilePermissions: ['camera'],
          ),
          macos: MacosSetup(
            entitlements: {'com.apple.security.network.client': true},
            urlSchemes: ['kiln'],
          ),
          web: WebSetup(indexHtml: true),
        ),
      );
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('plans one patch per declaration and applies it in memory', () {
      const setup = NativeSetup();
      final result = setup.plan(
        projectRoot: project,
        manifest: extension.manifest,
      );

      expect(
        result.patches.map((patch) => patch.id),
        containsAll(<String>[
          'android.permission.INTERNET',
          'android.url_scheme.kiln',
          'android.receiver.com.example.BootReceiver',
          'android.min_sdk',
          'android.compile_sdk',
          'ios.plist.NSFaceIDUsageDescription',
          'ios.podfile_permission.camera',
          'macos.entitlements.com.apple.security.network.client',
          'macos.url_scheme.kiln',
          'web.index.demo',
        ]),
      );
      expect(
        result.changes.keys,
        containsAll(<String>[
          kAndroidManifestPath,
          'android/app/build.gradle.kts',
          kIosInfoPlistPath,
          kIosPodfilePath,
          'macos/Runner/DebugProfile.entitlements',
          'macos/Runner/Info.plist',
          kWebIndexPath,
        ]),
      );

      final manifest = result.changes[kAndroidManifestPath]!;
      expect(manifest, contains('android.permission.INTERNET'));
      expect(manifest, contains('android:scheme="kiln"'));
      expect(manifest, contains('android:name="com.example.BootReceiver"'));
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
      expect(manifest, contains('android:exported="false"'));
      expect(
        result.changes[kMacosInfoPlistPath],
        contains('<string>kiln</string>'),
      );
    });

    test('revert restores the touched files', () {
      const setup = NativeSetup();
      final applied = setup.plan(
        projectRoot: project,
        manifest: extension.manifest,
      );

      final reverted = setup.revert(
        patches: applied.patches,
        projectRoot: project,
      );

      expect(
        reverted.changes[kAndroidManifestPath],
        isNot(contains('android.permission.INTERNET')),
      );
      expect(
        reverted.changes[kAndroidManifestPath],
        isNot(contains('android:scheme="kiln"')),
      );
      expect(
        reverted.changes[kAndroidManifestPath],
        isNot(contains('com.example.BootReceiver')),
      );
      expect(
        reverted.changes[kMacosInfoPlistPath],
        isNot(contains('<string>kiln</string>')),
      );
    });

    test('applies conditional patches only when answers match', () {
      final conditionalExtension = makeExtension(
        id: 'conditional',
        platformSetup: const PlatformSetup(
          android: AndroidSetup(permissions: ['android.permission.INTERNET']),
          conditionals: [
            NativeConditionalSetup(
              when: {'exact_alarms': true},
              android: AndroidSetup(
                permissions: ['android.permission.SCHEDULE_EXACT_ALARM'],
              ),
            ),
          ],
        ),
      );
      const setup = NativeSetup();

      final without = setup.plan(
        projectRoot: project,
        manifest: conditionalExtension.manifest,
      );
      expect(
        without.patches.map((patch) => patch.id),
        isNot(contains('android.permission.SCHEDULE_EXACT_ALARM')),
      );

      final matched = setup.plan(
        projectRoot: project,
        manifest: conditionalExtension.manifest,
        answers: const {'exact_alarms': true},
      );
      expect(
        matched.patches.map((patch) => patch.id),
        contains('android.permission.SCHEDULE_EXACT_ALARM'),
      );
      expect(
        matched.changes[kAndroidManifestPath],
        contains('android.permission.SCHEDULE_EXACT_ALARM'),
      );
    });

    test('only plans patches for folders that exist', () async {
      final empty = await Directory.systemTemp.createTemp('kiln_empty_');
      final result = const NativeSetup().plan(
        projectRoot: empty,
        manifest: extension.manifest,
      );

      expect(result.patches, isEmpty);
      await empty.delete(recursive: true);
    });
  });
}
