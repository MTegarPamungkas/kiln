import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'codegen brick renders the expected files',
    () async {
      final harness = ExtensionTestHarness(extensionRoot: Directory.current);

      final files = await harness.render(
        project: const {'name': 'codegen_app'},
      );
      final paths = files.map((file) => file.relativePath).toList();

      expect(
        paths,
        containsAll(<String>[
          'build.yaml',
          'lib/extensions/codegen/json_converters.dart',
          'lib/extensions/codegen/example/example_model.dart',
          'lib/extensions/codegen/example/example_model.freezed.dart',
          'lib/extensions/codegen/example/example_model.g.dart',
          'test/extensions/codegen/json_converters_test.dart',
          'test/extensions/codegen/example_model_test.dart',
        ]),
      );

      final build = files.firstWhere(
        (file) => file.relativePath == 'build.yaml',
      );
      final buildSource = String.fromCharCodes(build.bytes);
      expect(buildSource, contains('field_rename: snake'));
      expect(buildSource, contains('explicit_to_json: true'));

      final model = files.firstWhere(
        (file) => file.relativePath.endsWith('example_model.dart'),
      );
      final modelSource = String.fromCharCodes(model.bytes);
      expect(modelSource, contains('@freezed'));

      final golden = File(
        p.join(
          Directory.current.path,
          'test',
          'goldens',
          'rendered',
          'build.yaml.golden',
        ),
      );
      if (Platform.environment['UPDATE_GOLDENS'] == '1') {
        await golden.parent.create(recursive: true);
        await golden.writeAsString(buildSource);
      }
      expect(buildSource, golden.readAsStringSync());
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
