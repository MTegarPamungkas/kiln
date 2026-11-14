import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('rendered l10n extension passes flutter analyze', () async {
    final repoRoot = Directory.current.parent.parent;
    final temp = await Directory.systemTemp.createTemp('kiln_l10n_analyze_');

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
          'id': 'l10n',
          'app_name': 'ui_analyze',
          'locales': <String>['id', 'en'],
          'fallback_locale': 'id',
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
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.3
  kiln_core: $coreDependency
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  kiln_testing: $testingDependency
dependency_overrides:
  kiln_core: $coreDependency
flutter:
  generate: true
''');

      final pubGet = await Process.run(
        'flutter',
        const <String>['pub', 'get'],
        workingDirectory: temp.path,
        runInShell: Platform.isWindows,
      );
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}${pubGet.stderr}');

      final genL10n = await Process.run(
        'flutter',
        const <String>['gen-l10n'],
        workingDirectory: temp.path,
        runInShell: Platform.isWindows,
      );
      expect(genL10n.exitCode, 0, reason: '${genL10n.stdout}${genL10n.stderr}');

      // The extension owns lib/ and its generated tests. app_basic's own test
      // files are not part of this extension and are analyzed by the template
      // repository instead.
      final analyze = await Process.run(
        'flutter',
        const <String>['analyze', 'lib', 'test/extensions/l10n'],
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

Future<void> _writeFiles(Directory root, List<RenderedFile> files) async {
  for (final file in files) {
    final target = File(p.join(root.path, file.relativePath));
    await target.parent.create(recursive: true);
    await target.writeAsBytes(file.bytes);
  }
}
