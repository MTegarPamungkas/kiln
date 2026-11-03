import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('env brick renders code and example files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'env_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'env/development.example.json',
        'env/staging.example.json',
        'env/production.example.json',
        'lib/extensions/env/env_module.dart',
        'lib/extensions/env/build_env.dart',
        'lib/extensions/env/build_env_values.dart',
        'lib/extensions/env/env_keys.dart',
        'lib/extensions/env/env_schema.dart',
        'lib/extensions/env/env_validator.dart',
        'lib/extensions/env/env_x.dart',
        'lib/extensions/env/env_describe.dart',
        'lib/extensions/env/widgets/env_debug_page.dart',
        'test/extensions/env/env_x_test.dart',
      ]),
    );
    final schema = files.firstWhere(
      (file) => file.relativePath.endsWith('env_schema.dart'),
    );
    expect(String.fromCharCodes(schema.bytes), contains("'api_base_url'"));
  });
}
