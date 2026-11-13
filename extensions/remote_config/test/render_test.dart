import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'remote_config brick renders the expected files',
    () async {
      final harness = ExtensionTestHarness(extensionRoot: Directory.current);

      final files = await harness.render(
        project: const {'name': 'remote_config_app'},
      );
      final paths = files.map((file) => file.relativePath).toList();

      expect(
        paths,
        containsAll(<String>[
          'lib/extensions/remote_config/remote_config_config.dart',
          'lib/extensions/remote_config/remote_config_gateway.dart',
          'lib/extensions/remote_config/http_remote_config_gateway.dart',
          'lib/extensions/remote_config/remote_config_client.dart',
          'lib/extensions/remote_config/remote_config_failure_mapper.dart',
          'lib/extensions/remote_config/remote_config_support.dart',
          'lib/extensions/remote_config/remote_config_module.dart',
          'lib/extensions/remote_config/gate_remote_config.dart',
          'test/extensions/remote_config/test_support.dart',
          'test/extensions/remote_config/remote_config_contract_test.dart',
          'test/extensions/remote_config/remote_config_client_test.dart',
          'test/extensions/remote_config/remote_config_config_test.dart',
          'test/extensions/remote_config/remote_config_failure_mapper_test.dart',
          'test/extensions/remote_config/remote_config_support_test.dart',
          'test/extensions/remote_config/remote_config_module_test.dart',
          'test/extensions/remote_config/gate_remote_config_test.dart',
        ]),
      );

      final config = files.firstWhere(
        (file) => file.relativePath.endsWith('remote_config_config.dart'),
      );
      final source = String.fromCharCodes(config.bytes);
      expect(source, contains("endpoint = ''"));
      expect(source, contains('fetchInterval = const Duration(minutes: 15)'));

      final golden = File(
        p.join(
          Directory.current.path,
          'test',
          'goldens',
          'rendered',
          'lib',
          'extensions',
          'remote_config',
          'remote_config_config.dart.golden',
        ),
      );
      if (Platform.environment['UPDATE_GOLDENS'] == '1') {
        await golden.parent.create(recursive: true);
        await golden.writeAsString(source);
      }
      expect(source, golden.readAsStringSync());
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'remote_config renders an endpoint without HTML escaping',
    () async {
      final harness = ExtensionTestHarness(extensionRoot: Directory.current);

      final files = await harness.render(
        project: const {'name': 'remote_config_app'},
        answers: const <String, Object?>{
          'endpoint': 'https://config.example.dev/flags.json',
        },
      );
      final source = String.fromCharCodes(
        files
            .firstWhere(
              (file) =>
                  file.relativePath.endsWith('remote_config_config.dart'),
            )
            .bytes,
      );

      expect(
        source,
        contains("endpoint = 'https://config.example.dev/flags.json'"),
      );
      expect(source, isNot(contains('&#x2F;')));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
