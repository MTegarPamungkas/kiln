import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  const validator = ManifestValidator();

  group('ManifestValidator', () {
    test('accepts every valid fixture', () {
      for (final name in ['dio', 'http_retry', 'bloc', 'riverpod', 'flavors']) {
        final manifest = manifestFixtureByName(name);
        expect(
          validator.validate(manifest),
          isEmpty,
          reason: '$name should be valid',
        );
      }
    });

    test('rejects a capability required from itself', () {
      final manifest = ExtensionManifest.parse(
        readText('manifests/invalid/self_require.yaml'),
      );

      expect(
        validator.validate(manifest),
        contains(contains('cannot require its own capability')),
      );
    });

    test('rejects invalid id, version, and prompt options', () {
      final manifest = ExtensionManifest.parse(
        readText('manifests/invalid/bad_prompt.yaml'),
      );
      final errors = validator.validate(manifest);

      expect(errors, contains(contains('id must be snake_case')));
      expect(errors, contains(contains('version must be semver')));
      expect(errors, contains(contains('must declare options')));
    });

    test('throws with every error in one exception', () {
      final manifest = ExtensionManifest.parse(
        readText('manifests/invalid/bad_prompt.yaml'),
      );

      expect(
        () => validator.throwIfInvalid(manifest),
        throwsA(
          isA<KilnException>()
              .having((error) => error.code, 'code', 'manifest.invalid')
              .having((error) => error.details['errors'], 'errors', isNotEmpty),
        ),
      );
    });

    test('detects duplicate prompts and slots', () {
      final manifest = ExtensionManifest(
        id: 'dupes',
        name: 'Dupes',
        version: '1.0.0',
        description: 'Duplicates',
        category: 'tooling',
        slots: const [
          SlotDeclaration(name: 'a', item: 'X'),
          SlotDeclaration(name: 'a', item: 'Y'),
        ],
        prompts: const [
          PromptSpec(name: 'value', type: PromptType.string),
          PromptSpec(name: 'value', type: PromptType.string),
        ],
      );

      final errors = validator.validate(manifest);
      expect(errors, contains(contains('slot "a" is declared twice')));
      expect(errors, contains(contains('prompt "value" is declared twice')));
    });

    test('rejects invalid Android receiver declarations', () {
      final manifest = ExtensionManifest(
        id: 'receivers',
        name: 'Receivers',
        version: '1.0.0',
        description: 'Receivers',
        category: 'tooling',
        platformSetup: const PlatformSetup(
          android: AndroidSetup(
            receivers: [
              AndroidReceiverSetup(
                name: 'NoPackage',
                actions: ['not an action'],
              ),
              AndroidReceiverSetup(
                name: 'com.example.Dup',
                actions: ['android.intent.action.BOOT_COMPLETED'],
              ),
              AndroidReceiverSetup(name: 'com.example.Dup'),
            ],
          ),
        ),
      );

      final errors = validator.validate(manifest);

      expect(
        errors,
        contains(contains('receiver name "NoPackage" is invalid')),
      );
      expect(errors, contains(contains('invalid action "not an action"')));
      expect(
        errors,
        contains(contains('receiver "com.example.Dup" is declared twice')),
      );
    });
    test('rejects invalid native manifest values', () {
      final manifest = ExtensionManifest(
        id: 'native',
        name: 'Native',
        version: '1.0.0',
        description: 'Native values',
        category: 'tooling',
        platformSetup: const PlatformSetup(
          android: AndroidSetup(
            permissions: [
              'internet',
              'android.permission.INTERNET',
              'android.permission.INTERNET',
            ],
            urlSchemes: ['kiln', '1bad', 'kiln'],
            appLinkHosts: ['kiln.dev', 'bad host'],
            appLinkPathPrefixes: ['profile'],
          ),
          ios: IosSetup(urlSchemes: ['kiln', 'kiln']),
          macos: MacosSetup(urlSchemes: ['kiln', 'kiln']),
        ),
      );

      final errors = validator.validate(manifest);

      expect(errors, contains(contains('permission "internet" is invalid')));
      expect(
        errors,
        contains(
          contains('permission "android.permission.INTERNET" is duplicated'),
        ),
      );
      expect(
        errors,
        contains(contains('Android URL scheme "1bad" is invalid')),
      );
      expect(errors, contains(contains('iOS URL scheme "kiln" is duplicated')));
      expect(
        errors,
        contains(contains('macOS URL scheme "kiln" is duplicated')),
      );
      expect(errors, contains(contains('App Link host "bad host" is invalid')));
      expect(
        errors,
        contains(contains('App Link path prefix "profile" is invalid')),
      );
    });
    test('validates conditional native setup', () {
      final manifest = ExtensionManifest(
        id: 'conditional',
        name: 'Conditional',
        version: '1.0.0',
        description: 'Conditional native setup',
        category: 'tooling',
        prompts: const [
          PromptSpec(name: 'exact_alarms', type: PromptType.boolValue),
        ],
        platformSetup: const PlatformSetup(
          conditionals: [
            NativeConditionalSetup(
              when: {'missing': true},
              android: AndroidSetup(permissions: ['bad permission']),
            ),
            NativeConditionalSetup(
              when: {},
              android: AndroidSetup(permissions: ['android.permission.CAMERA']),
            ),
            NativeConditionalSetup(when: {'exact_alarms': true}),
          ],
        ),
      );

      final errors = validator.validate(manifest);

      expect(errors, contains(contains('unknown prompt "missing"')));
      expect(errors, contains(contains('must declare when')));
      expect(errors, contains(contains('has no platform entries')));
      expect(
        errors,
        contains(contains('permission "bad permission" is invalid')),
      );
    });
  });
}
