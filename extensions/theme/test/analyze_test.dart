import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('rendered theme extension passes flutter analyze', () async {
    final repoRoot = Directory.current.parent.parent;
    final temp = await Directory.systemTemp.createTemp('kiln_theme_analyze_');

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
      for (final file in appFiles) {
        await _write(temp, file);
      }

      // app_basic ships a live-mode test that imports kiln_testing without
      // using it. Remove that unrelated import from the fixture so the theme
      // extension owns every analyzer finding in this rendered project.
      final appThemeModeTest = File(
        p.join(temp.path, 'test', 'app', 'app_theme_mode_test.dart'),
      );
      if (appThemeModeTest.existsSync()) {
        final source = await appThemeModeTest.readAsString();
        await appThemeModeTest.writeAsString(
          source.replaceFirst(
            "import 'package:kiln_testing/kiln_testing.dart';\n",
            '',
          ),
        );
      }

      final extensionFiles = await const BrickRenderer().render(
        bundle: createBundle(
          Directory(p.join(Directory.current.path, 'brick')),
        ),
        vars: const <String, dynamic>{
          'id': 'theme',
          'app_name': 'ui_analyze',
          'seed_color': '#0F766E',
          'font_family': '',
          'corner_radius': 14,
          'density': 'comfortable',
        },
      );
      for (final file in extensionFiles) {
        await _write(temp, file);
      }

      final corePath = Directory(p.join(repoRoot.path, 'packages', 'kiln_core'));
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
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<void> _write(Directory root, RenderedFile file) async {
  final target = File(p.join(root.path, file.relativePath));
  await target.parent.create(recursive: true);
  await target.writeAsBytes(file.bytes);
}
