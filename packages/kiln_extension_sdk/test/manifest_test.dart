import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('ExtensionManifest', () {
    test('parses the dio manifest completely', () {
      final manifest = manifestFixtureByName('dio');

      expect(manifest.id, 'dio');
      expect(manifest.name, 'Dio HTTP client');
      expect(manifest.version, '0.2.0');
      expect(manifest.category, 'network');
      expect(manifest.tier, ExtensionTier.official);
      expect(manifest.exclusive, isFalse);
      expect(manifest.provides, ['http_client', 'http_pipeline']);
      expect(manifest.slots.single.name, 'http.interceptors');
      expect(manifest.slots.single.item, 'HttpMiddleware');
      expect(manifest.prompts, hasLength(2));
      expect(manifest.promptsByName['base_url']?.required, isTrue);
      expect(manifest.dependencies['dio'], '^5.9.0');
      expect(manifest.platformSetup.android.permissions, [
        'android.permission.INTERNET',
      ]);
      expect(
        manifest
            .platformSetup
            .macos
            .entitlements['com.apple.security.network.client'],
        isTrue,
      );
      expect(manifest.compatibility.kiln, '>=0.2.0 <0.3.0');
      expect(manifest.semverVersion.toString(), '0.2.0');
    });

    test('parses and serializes Android receivers', () {
      final manifest = ExtensionManifest.parse('''
id: receivers
name: Receivers
version: 1.0.0
description: Receiver manifest
category: tooling
android:
  receivers:
    - name: com.example.BootReceiver
      actions:
        - android.intent.action.BOOT_COMPLETED
        - android.intent.action.MY_PACKAGE_REPLACED
    - name: com.example.ExportedReceiver
      exported: true
''');

      final receivers = manifest.platformSetup.android.receivers;
      expect(receivers, hasLength(2));
      expect(receivers.first.name, 'com.example.BootReceiver');
      expect(receivers.first.exported, isFalse);
      expect(receivers.first.actions, [
        'android.intent.action.BOOT_COMPLETED',
        'android.intent.action.MY_PACKAGE_REPLACED',
      ]);
      expect(receivers.last.exported, isTrue);

      final android = manifest.toJson()['android']! as Map<String, Object?>;
      expect(android['receivers'], [
        {
          'name': 'com.example.BootReceiver',
          'actions': [
            'android.intent.action.BOOT_COMPLETED',
            'android.intent.action.MY_PACKAGE_REPLACED',
          ],
        },
        {'name': 'com.example.ExportedReceiver', 'exported': true},
      ]);
    });

    test('parses and serializes macOS URL schemes', () {
      final manifest = ExtensionManifest.parse('''
id: macos_links
name: macOS links
version: 1.0.0
description: macOS URL schemes
category: deep_link
macos:
  url_schemes: [kiln-auth]
''');

      expect(manifest.platformSetup.macos.urlSchemes, ['kiln-auth']);
      expect(manifest.toJson()['macos'], {
        'url_schemes': ['kiln-auth'],
      });
    });

    test('parses and serializes conditional native setup', () {
      final manifest = ExtensionManifest.parse('''
id: conditional
name: Conditional
version: 1.0.0
description: Conditional native setup
category: tooling
prompts:
  - name: exact_alarms
    type: bool
conditional:
  - when:
      exact_alarms: true
    android:
      permissions: [android.permission.SCHEDULE_EXACT_ALARM]
''');

      final conditional = manifest.platformSetup.conditionals.single;
      expect(conditional.when, {'exact_alarms': true});
      expect(conditional.android.permissions, [
        'android.permission.SCHEDULE_EXACT_ALARM',
      ]);
      expect(manifest.toJson()['conditional'], [
        {
          'when': {'exact_alarms': true},
          'android': {
            'permissions': ['android.permission.SCHEDULE_EXACT_ALARM'],
          },
        },
      ]);
    });

    test('conditional setup matches one value inside a multi answer', () {
      final manifest = ExtensionManifest.parse('''
id: kinds
name: Kinds
version: 1.0.0
description: Multi value condition
category: tooling
prompts:
  - name: kinds
    type: multi
    options: [camera, microphone]
conditional:
  - when:
      kinds: camera
    android:
      permissions: [android.permission.CAMERA]
''');

      final conditional = manifest.platformSetup.conditionals.single;
      expect(
        conditional.matches(<String, Object?>{
          'kinds': <String>['camera', 'microphone'],
        }),
        isTrue,
      );
      expect(
        conditional.matches(<String, Object?>{
          'kinds': <String>['microphone'],
        }),
        isFalse,
      );
    });

    test('parses an exclusive state management extension', () {
      final bloc = manifestFixtureByName('bloc');

      expect(bloc.exclusive, isTrue);
      expect(bloc.provides, ['state_bloc']);
      expect(bloc.category, 'state');
    });

    test('parses contributions with priority and conditions', () {
      final retry = manifestFixtureByName('http_retry');

      expect(retry.requires, ['http_client', 'http_pipeline']);
      expect(retry.contributions.single.slot, 'http.interceptors');
      expect(retry.contributions.single.priority, 20);
      expect(retry.contributions.single.when, ['http_pipeline']);
    });

    test('rejects a root that is not a map', () {
      expect(
        () => ExtensionManifest.parse('- not a map'),
        throwsA(isA<KilnException>()),
      );
    });

    test('toJson keeps the fields the registry needs', () {
      final manifest = manifestFixtureByName('flavors');
      final json = manifest.toJson();

      expect(json['id'], 'flavors');
      expect(json['exclusive'], isTrue);
      expect(json['contributes'], isA<List<Object?>>());
    });
  });
}
