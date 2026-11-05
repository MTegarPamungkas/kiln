import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('http_cache brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'cache_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/http_cache/http_cache_module.dart',
        'lib/extensions/http_cache/cache_interceptor.dart',
        'lib/extensions/http_cache/memory_http_cache.dart',
        'lib/extensions/http_cache/storage_http_cache.dart',
        'lib/extensions/http_cache/etag_validator.dart',
      ]),
    );
    final settings = files.firstWhere(
      (file) => file.relativePath.endsWith('cache_settings.dart'),
    );
    expect(
      String.fromCharCodes(settings.bytes),
      contains('Duration(seconds: 60)'),
    );
  });
}
