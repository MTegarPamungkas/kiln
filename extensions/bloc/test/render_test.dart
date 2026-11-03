import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('bloc brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'bloc_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/app/bloc_providers.dart',
        'lib/extensions/bloc/bloc_module.dart',
        'lib/core/bloc/base_cubit.dart',
        'lib/core/bloc/async_cubit.dart',
        'lib/core/bloc/session_cubit.dart',
      ]),
    );
    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('bloc_module.dart'),
    );
    expect(String.fromCharCodes(module.bytes), contains("'state_bloc'"));
  });
}
