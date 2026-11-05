import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('biometric brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'secure_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/biometric/biometric.dart',
        'lib/extensions/biometric/biometric_module.dart',
        'lib/extensions/biometric/biometric_config.dart',
        'lib/extensions/biometric/biometric_failure_mapper.dart',
        'lib/extensions/biometric/biometric_gateway.dart',
        'lib/extensions/biometric/biometric_availability.dart',
        'lib/extensions/biometric/biometric_gate.dart',
        'lib/extensions/biometric/app_lock.dart',
        'lib/extensions/biometric/biometric_protected_storage.dart',
        'test/extensions/biometric/biometric_module_test.dart',
      ]),
    );
    expect(
      files.map((file) => file.relativePath),
      isNot(contains('lib/extensions/biometric/app_lock_scope.dart')),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('biometric_config.dart'),
    );
    expect(
      String.fromCharCodes(config.bytes),
      contains('gracePeriod: Duration(seconds: 30)'),
    );
  });
}
