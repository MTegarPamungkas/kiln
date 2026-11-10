import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Walks up from the example until the Kiln checkout root is found.
Directory findRepoRoot() {
  var directory = Directory.current.absolute;
  while (directory.parent.path != directory.path) {
    if (Directory(p.join(directory.path, 'packages', 'kiln_core'))
        .existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not locate the Kiln repository root.');
}

void main() {
  test('rendered output passes flutter analyze', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);
    final files = await harness.render(
      project: const {'name': 'demo_analyze'},
      answers: const {'app_name': 'demo_analyze'},
    );
    final temp = await Directory.systemTemp.createTemp('kiln_ext_analyze_');

    try {
      for (final file in files) {
        final target = File(p.join(temp.path, file.relativePath));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(file.bytes);
      }

      final repoRoot = findRepoRoot();
      final corePath = p.join(repoRoot.path, 'packages', 'kiln_core');
      final testingPath = p.join(repoRoot.path, 'packages', 'kiln_testing');
      final coreDependency = '{path: ${corePath.replaceAll('\\', '/')}}';
      final testingDependency = '{path: ${testingPath.replaceAll('\\', '/')}}';
      await File(p.join(temp.path, 'pubspec.yaml')).writeAsString('''
name: demo_analyze
publish_to: none
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
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
        // The analyzer can hold a handle briefly on Windows.
      }
    }
  });
}
