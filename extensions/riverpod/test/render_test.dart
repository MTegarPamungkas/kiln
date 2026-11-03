import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('riverpod brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'riverpod_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/app/provider_root.dart',
        'lib/extensions/riverpod/riverpod_module.dart',
        'lib/core/riverpod/kiln_providers.dart',
        'lib/core/riverpod/session_notifier.dart',
      ]),
    );
    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('riverpod_module.dart'),
    );
    expect(String.fromCharCodes(module.bytes), contains("'state_riverpod'"));
  });
}
