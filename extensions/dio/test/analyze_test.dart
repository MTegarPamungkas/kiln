import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('rendered extension passes flutter analyze', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);
    final files = await harness.render(
      answers: const {
        'base_url': 'https://api.kiln.dev',
        'connect_timeout': 15,
      },
      project: const {'name': 'dio_analyze'},
    );
    final temp = await Directory.systemTemp.createTemp('kiln_dio_analyze_');

    try {
      for (final file in files) {
        final target = File(p.join(temp.path, file.relativePath));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(file.bytes);
      }

      final repoRoot = Directory.current.parent.parent;
      final corePath = Directory(
        p.join(repoRoot.path, 'packages', 'kiln_core'),
      );
      final testingPath = Directory(
        p.join(repoRoot.path, 'packages', 'kiln_testing'),
      );
      final coreDependency = corePath.existsSync()
          ? '{path: ${corePath.path.replaceAll('\\', '/')}}'
          : '^0.1.0';
      final testingDependency = testingPath.existsSync()
          ? '{path: ${testingPath.path.replaceAll('\\', '/')}}'
          : '^0.1.0';
      await File(p.join(temp.path, 'pubspec.yaml')).writeAsString('''
name: dio_analyze
publish_to: none
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.11.1
  kiln_core: $coreDependency
dev_dependencies:
  flutter_test:
    sdk: flutter
  kiln_testing: $testingDependency
dependency_overrides:
  kiln_core: $coreDependency
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
      expect(analyze.exitCode, 0, reason: '${analyze.stdout}${analyze.stderr}');
    } finally {
      try {
        await temp.delete(recursive: true);
      } on FileSystemException {
        // The Flutter analysis server can hold a handle briefly on Windows.
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
