import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('notifications manifest is valid', () {
    final manifest = ExtensionManifest.parse(
      File('extension.yaml').readAsStringSync(),
      rootPath: Directory.current.path,
    );

    expect(const ManifestValidator().validate(manifest), isEmpty);
    expect(manifest.provides, ['notifications']);
    expect(manifest.optionalRequires, contains('permission'));
    expect(manifest.dependencies, contains('flutter_local_notifications'));
    expect(
      manifest.platformSetup.android.permissions,
      contains('android.permission.POST_NOTIFICATIONS'),
    );
    expect(
      manifest.platformSetup.android.receivers.map((receiver) => receiver.name),
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
      ),
    );
  });
}
