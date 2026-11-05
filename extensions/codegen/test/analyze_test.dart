import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'rendered codegen extension passes flutter analyze',
    () async {
      final temp = await Directory.systemTemp.createTemp('kiln_codegen_');

      try {
        final files = await const BrickRenderer().render(
          bundle: createBundle(
            Directory(p.join(Directory.current.path, 'brick')),
          ),
          vars: const <String, dynamic>{
            'id': 'codegen',
            'app_name': 'codegen_analyze',
            'generators': <String>['json_serializable', 'freezed'],
          },
        );
        for (final file in files) {
          final target = File(p.join(temp.path, file.relativePath));
          await target.parent.create(recursive: true);
          await target.writeAsBytes(file.bytes);
        }

        await File(p.join(temp.path, 'pubspec.yaml')).writeAsString('''
name: codegen_analyze
publish_to: none
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
  json_annotation: ^4.12.0
  freezed_annotation: ^3.1.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
''');

        final pubGet = await Process.run(
          'flutter',
          const ['pub', 'get'],
          workingDirectory: temp.path,
          runInShell: Platform.isWindows,
        );
        expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}${pubGet.stderr}');

        final analyze = await Process.run(
          'flutter',
          const ['analyze'],
          workingDirectory: temp.path,
          runInShell: Platform.isWindows,
        );
        expect(
          analyze.exitCode,
          0,
          reason: '${analyze.stdout}${analyze.stderr}',
        );
      } finally {
        try {
          await temp.delete(recursive: true);
        } on FileSystemException {
          // The analysis server can hold a handle briefly on Windows.
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
