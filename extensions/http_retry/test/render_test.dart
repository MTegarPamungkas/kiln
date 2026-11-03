import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('http_retry brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'retry_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/http_retry/http_retry_module.dart',
        'lib/extensions/http_retry/retry_middleware.dart',
        'lib/extensions/http_retry/retry_settings.dart',
        'lib/extensions/http_retry/backoff.dart',
        'lib/extensions/http_retry/retry_budget.dart',
      ]),
    );
    final settings = files.firstWhere(
      (file) => file.relativePath.endsWith('retry_settings.dart'),
    );
    expect(String.fromCharCodes(settings.bytes), contains('maxAttempts: 3'));
  });
}
