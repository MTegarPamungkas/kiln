import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final update = arguments.contains('--update');
  final analyze = arguments.contains('--analyze');
  final tests = arguments.contains('--test');
  final onlyIndex = arguments.indexOf('--only');
  final only = onlyIndex >= 0 && onlyIndex + 1 < arguments.length
      ? arguments[onlyIndex + 1]
      : null;
  final root = Directory.current.absolute;
  final extensionDirs =
      Directory(p.join(root.path, 'extensions'))
          .listSync()
          .whereType<Directory>()
          .where(
            (directory) =>
                File(p.join(directory.path, 'extension.yaml')).existsSync(),
          )
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  final failure = StringBuffer();

  final appBasic = createBundle(
    Directory(p.join(root.path, 'bricks', 'app_basic')),
  );
  final appFiles = await const BrickRenderer().render(
    bundle: appBasic,
    vars: const <String, dynamic>{
      'name': 'verify_app',
      'description': 'Kiln analyze fixture.',
      'org': 'dev.kiln',
      'state': 'none',
      'platforms': <String>['android', 'ios'],
      'minimal': true,
    },
  );

  for (final directory in extensionDirs) {
    final id = p.basename(directory.path);
    if (only != null && id != only) {
      continue;
    }
    final manifest = ExtensionManifest.parse(
      File(p.join(directory.path, 'extension.yaml')).readAsStringSync(),
      rootPath: directory.path,
    );
    final bundle = createBundle(Directory(p.join(directory.path, 'brick')));
    final vars = _vars(manifest);
    final rendered = await const BrickRenderer().render(
      bundle: bundle,
      vars: vars,
    );
    final goldenFile = File(
      p.join(directory.path, 'test', 'goldens', 'rendered.json'),
    );
    final golden = _golden(manifest.id, rendered);
    if (update) {
      await goldenFile.parent.create(recursive: true);
      await goldenFile.writeAsString(golden);
      stdout.writeln('updated ${p.relative(goldenFile.path, from: root.path)}');
    } else {
      if (!goldenFile.existsSync()) {
        failure.writeln(
          'missing golden: ${p.relative(goldenFile.path, from: root.path)}',
        );
      } else if (goldenFile.readAsStringSync() != golden) {
        failure.writeln(
          'out of date: ${p.relative(goldenFile.path, from: root.path)}',
        );
      }
    }

    if (analyze || tests) {
      final passed = await _analyzeExtension(
        root: root,
        manifest: manifest,
        rendered: rendered,
        appFiles: appFiles,
        runAnalysis: analyze,
        runTests: tests,
      );
      if (!passed) {
        failure.writeln('extension checks failed: $id');
      }
    }
  }

  if (failure.isNotEmpty) {
    stderr.write(failure);
    exitCode = 1;
  }
}

Map<String, dynamic> _vars(ExtensionManifest manifest) {
  final vars = <String, dynamic>{'id': manifest.id, 'app_name': 'verify_app'};
  for (final prompt in manifest.prompts) {
    if (prompt.defaultValue != null) {
      vars[prompt.name] = prompt.defaultValue;
      continue;
    }
    vars[prompt.name] = switch (prompt.type) {
      PromptType.url => 'https://api.example.com',
      PromptType.secret => 'test-secret',
      PromptType.intValue => prompt.min ?? 1,
      PromptType.boolValue => false,
      PromptType.enumValue =>
        prompt.options.isEmpty ? 'default' : prompt.options.first,
      PromptType.multi =>
        prompt.options.isEmpty ? <String>[] : <String>[prompt.options.first],
      PromptType.string => 'sample',
    };
  }
  return vars;
}

String _golden(String id, List<RenderedFile> files) {
  final entries = <String, String>{
    for (final file in files)
      file.relativePath: sha256.convert(file.bytes).toString(),
  };
  final sorted = Map<String, String>.fromEntries(
    entries.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key)),
  );
  return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{'extension': id, 'files': sorted})}\n';
}

Future<bool> _analyzeExtension({
  required Directory root,
  required ExtensionManifest manifest,
  required List<RenderedFile> rendered,
  required List<RenderedFile> appFiles,
  bool runAnalysis = true,
  bool runTests = false,
}) async {
  final temp = await Directory.systemTemp.createTemp(
    'kiln_verify_${manifest.id}_',
  );
  try {
    for (final file in <RenderedFile>[...appFiles, ...rendered]) {
      final target = File(p.join(temp.path, file.relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(file.bytes);
    }
    final core = p
        .join(root.path, 'packages', 'kiln_core')
        .replaceAll('\\', '/');
    final testing = p
        .join(root.path, 'packages', 'kiln_testing')
        .replaceAll('\\', '/');
    final dependencies = StringBuffer('  flutter:\n    sdk: flutter\n');
    if (!manifest.dependencies.containsKey('kiln_core')) {
      dependencies.writeln('  kiln_core:\n    path: $core');
    }
    for (final entry in manifest.dependencies.entries) {
      if (entry.key == 'kiln_core') {
        continue;
      }
      final value = entry.value;
      if (value is Map) {
        dependencies.writeln('  ${entry.key}:');
        for (final nested in value.entries) {
          dependencies.writeln('    ${nested.key}: ${nested.value}');
        }
      } else {
        dependencies.writeln('  ${entry.key}: $value');
      }
    }
    final flutterConfig = manifest.raw['flutter'];
    final generate = flutterConfig is Map && flutterConfig['generate'] == true;
    await File(p.join(temp.path, 'pubspec.yaml')).writeAsString('''
name: verify_app
publish_to: none
environment:
  sdk: ^3.13.0
dependencies:
$dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  kiln_testing:
    path: $testing
dependency_overrides:
  kiln_core:
    path: $core
${generate ? '''
flutter:
  generate: true
''' : ''}''');
    final pubGet = await Process.run(
      'flutter',
      const <String>['pub', 'get'],
      workingDirectory: temp.path,
      runInShell: Platform.isWindows,
    );
    if (pubGet.exitCode != 0) {
      stderr.writeln('${manifest.id}: ${pubGet.stdout}${pubGet.stderr}');
      return false;
    }
    if (runAnalysis) {
      final analyze = await Process.run(
        'flutter',
        const <String>['analyze'],
        workingDirectory: temp.path,
        runInShell: Platform.isWindows,
      );
      if (analyze.exitCode != 0) {
        stderr.writeln('${manifest.id}: ${analyze.stdout}${analyze.stderr}');
        return false;
      }
      stdout.writeln('analyzed ${manifest.id}');
    }
    if (runTests) {
      final test = await Process.run(
        'flutter',
        const <String>['test'],
        workingDirectory: temp.path,
        runInShell: Platform.isWindows,
      );
      if (test.exitCode != 0) {
        stderr.writeln('${manifest.id}: ${test.stdout}${test.stderr}');
        return false;
      }
      stdout.writeln('tested ${manifest.id}');
    }
    return true;
  } finally {
    try {
      await temp.delete(recursive: true);
    } on FileSystemException {
      // The analysis server can hold a handle briefly on Windows.
    }
  }
}
