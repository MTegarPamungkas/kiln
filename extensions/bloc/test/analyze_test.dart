import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('rendered bloc extension passes flutter analyze', () async {
    final repoRoot = Directory.current.parent.parent;
    final temp = await Directory.systemTemp.createTemp('kiln_bloc_analyze_');

    try {
      final appBundle = createBundle(
        Directory(p.join(repoRoot.path, 'bricks', 'app_basic')),
      );
      final appFiles = await const BrickRenderer().render(
        bundle: appBundle,
        vars: const <String, dynamic>{
          'name': 'bloc_analyze',
          'description': 'Bloc analyze app.',
          'org': 'com.example',
          'state': 'bloc',
        },
      );
      final extensionFiles = await const BrickRenderer().render(
        bundle: createBundle(
          Directory(p.join(Directory.current.path, 'brick')),
        ),
        vars: const <String, dynamic>{'id': 'bloc', 'app_name': 'bloc_analyze'},
      );

      for (final file in <RenderedFile>[...appFiles, ...extensionFiles]) {
        final target = File(p.join(temp.path, file.relativePath));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(file.bytes);
      }

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
name: bloc_analyze
publish_to: none
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
  bloc: ^9.2.1
  flutter_bloc: ^9.1.1
  bloc_concurrency: ^0.3.0
  rxdart: ^0.28.0
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
        // The analysis server can hold a handle briefly on Windows.
      }
    }
  });
}
