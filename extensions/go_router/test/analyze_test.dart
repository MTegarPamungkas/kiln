import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('rendered go_router extension passes flutter analyze', () async {
    final repoRoot = Directory.current.parent.parent;
    final temp = await Directory.systemTemp.createTemp('kiln_router_analyze_');

    try {
      final appFiles = await const BrickRenderer().render(
        bundle: createBundle(
          Directory(p.join(repoRoot.path, 'bricks', 'app_basic')),
        ),
        vars: const <String, dynamic>{
          'name': 'ui_analyze',
          'description': 'A Kiln app.',
          'org': 'com.example',
          'state': 'none',
          'platforms': <String>['android', 'ios'],
        },
      );
      await _writeFiles(temp, appFiles);

      final extensionFiles = await const BrickRenderer().render(
        bundle: createBundle(
          Directory(p.join(Directory.current.path, 'brick')),
        ),
        vars: const <String, dynamic>{
          'id': 'go_router',
          'app_name': 'ui_analyze',
        },
      );
      await _writeFiles(temp, extensionFiles);

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
name: ui_analyze
publish_to: none
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
  go_router: ^18.1.2
  kiln_core: $coreDependency
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  kiln_testing: $testingDependency
dependency_overrides:
  kiln_core: $coreDependency
''');

      final pubGet = await Process.run(
        'flutter',
        const <String>['pub', 'get'],
        workingDirectory: temp.path,
        runInShell: Platform.isWindows,
      );
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}${pubGet.stderr}');

      // app_basic ships a theme mode test with an unused import, so analysis is
      // scoped to the library and the extension test files rendered here.
      final analyze = await Process.run(
        'flutter',
        const <String>[
          'analyze',
          'lib',
          'test/extensions/go_router',
        ],
        workingDirectory: temp.path,
        runInShell: Platform.isWindows,
      );
      expect(analyze.exitCode, 0, reason: '${analyze.stdout}${analyze.stderr}');
    } finally {
      try {
        await temp.delete(recursive: true);
      } on FileSystemException {
        // The analysis server can hold a handle briefly on Windows.
      }
    }
  });
}

Future<void> _writeFiles(Directory root, List<RenderedFile> files) async {
  for (final file in files) {
    final target = File(p.join(root.path, file.relativePath));
    await target.parent.create(recursive: true);
    await target.writeAsBytes(file.bytes);
  }
}
