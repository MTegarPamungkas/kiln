import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('brick renders the dio extension files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      answers: const {
        'base_url': 'https://api.kiln.dev',
        'connect_timeout': 15,
      },
    );

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/dio/dio_module.dart',
        'lib/extensions/dio/dio_client.dart',
        'lib/extensions/dio/dio_config.dart',
        'lib/extensions/dio/dio_failure_mapper.dart',
        'lib/extensions/dio/interceptors/request_id_interceptor.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('dio_config.dart'),
    );
    expect(
      String.fromCharCodes(config.bytes),
      contains('https://api.kiln.dev'),
    );
  });
}
