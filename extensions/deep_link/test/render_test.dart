import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('deep_link brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'link_app'});
    final paths = files.map((file) => file.relativePath).toList();

    expect(
      paths,
      containsAll(<String>[
        'lib/extensions/deep_link/deep_link_module.dart',
        'lib/extensions/deep_link/device_deep_links.dart',
        'lib/extensions/deep_link/deep_link_gateway.dart',
        'lib/extensions/deep_link/app_links_gateway.dart',
        'lib/extensions/deep_link/deep_link_config.dart',
        'lib/extensions/deep_link/deep_link_failure_mapper.dart',
        'lib/extensions/deep_link/link_allowlist.dart',
        'lib/extensions/deep_link/link_normalizer.dart',
        'lib/extensions/deep_link/link_deduplicator.dart',
        'lib/extensions/deep_link/pending_link_buffer.dart',
        'lib/extensions/deep_link/app_link_builder.dart',
        'test/extensions/deep_link/device_deep_links_test.dart',
        'test/extensions/deep_link/deep_link_module_test.dart',
        'test/extensions/deep_link/deep_link_config_test.dart',
        'test/extensions/deep_link/deep_link_failure_mapper_test.dart',
        'test/extensions/deep_link/link_allowlist_test.dart',
        'test/extensions/deep_link/link_normalizer_test.dart',
        'test/extensions/deep_link/link_deduplicator_test.dart',
        'test/extensions/deep_link/pending_link_buffer_test.dart',
        'test/extensions/deep_link/app_link_builder_test.dart',
        'test/extensions/deep_link/deep_links_contract_test.dart',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('deep_link_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("scheme: 'kiln'"));
    expect(source, contains("'kiln.dev'"));

    final golden = File(
      p.join(
        Directory.current.path,
        'test',
        'goldens',
        'rendered',
        'lib',
        'extensions',
        'deep_link',
        'deep_link_config.dart.golden',
      ),
    );
    if (Platform.environment['UPDATE_GOLDENS'] == '1') {
      await golden.parent.create(recursive: true);
      await golden.writeAsString(source);
    }
    expect(source, golden.readAsStringSync());
  });

  test('deep_link brick renders prompt answers', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      project: const {'name': 'link_app'},
      answers: const <String, Object?>{
        'scheme': 'myapp',
        'hosts': <String>['app.kiln.dev'],
        'path_prefixes': <String>['/app'],
      },
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('deep_link_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("scheme: 'myapp'"));
    expect(source, contains("'app.kiln.dev'"));
    expect(source, contains("'/app'"));
  });
}
