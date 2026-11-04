import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('permission brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'safe_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/permission/permission_module.dart',
        'lib/extensions/permission/permission_flow.dart',
        'lib/extensions/permission/permission_kind_guard.dart',
        'lib/extensions/permission/permission_resume_observer.dart',
        'lib/extensions/permission/gate_permission.dart',
        'test/extensions/permission/gate_permission_test.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('permission_config.dart'),
    );
    expect(
      String.fromCharCodes(config.bytes),
      contains('PermissionKind.camera'),
    );
  });
}
