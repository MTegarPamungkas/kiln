import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// Renders dio + http_cache into one disposable project.
///
/// The per-extension verifier renders a single extension, so it cannot compose
/// the transport (dio) with the cache middleware (http_cache). This fixture does
/// that, writes [dio_cache_composition_test.dart.template] into it, and runs the
/// suite against a loopback HTTP server.
///
/// Usage (from the repository root):
///
/// ```
/// dart run tool/e2e/dio_cache_probe.dart
/// ```
Future<void> main(List<String> arguments) async {
  final root = Directory.current.path;
  final fixture = Directory(p.join(root, '.dart_tool', 'dio_cache_probe'));
  await fixture.create(recursive: true);

  final dependencies = <String, Object?>{
    'flutter': <String, Object?>{'sdk': 'flutter'},
    'kiln_core': <String, Object?>{
      'path': p.join(root, 'packages', 'kiln_core').replaceAll('\\', '/'),
    },
  };
  for (final id in const <String>['dio', 'http_cache']) {
    final source = Directory(p.join(root, 'extensions', id));
    final manifest = ExtensionManifest.parse(
      File(p.join(source.path, 'extension.yaml')).readAsStringSync(),
    );
    final bundle = createBundle(Directory(p.join(source.path, 'brick')));
    dependencies.addAll(manifest.dependencies);
    final answers = <String, Object?>{
      for (final prompt in manifest.prompts)
        prompt.name: prompt.defaultValue ?? _fallbackAnswer(prompt),
    };
    final files = await const BrickRenderer().render(
      bundle: bundle,
      vars: buildTemplateVars(
        extension: AvailableExtension(manifest: manifest, bundle: bundle),
        project: const <String, Object?>{'name': 'e2e_dio_cache'},
        answers: answers,
      ),
    );
    for (final file in files.where(
      (file) => file.relativePath.startsWith('lib/'),
    )) {
      final target = File(p.join(fixture.path, file.relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(file.bytes);
    }
  }

  await File(p.join(fixture.path, 'pubspec.yaml')).writeAsString(
    jsonEncode(<String, Object?>{
      'name': 'e2e_dio_cache',
      'publish_to': 'none',
      'environment': <String, Object?>{'sdk': '^3.13.0'},
      'dependencies': dependencies,
      'dev_dependencies': <String, Object?>{
        'flutter_test': <String, Object?>{'sdk': 'flutter'},
      },
    }),
  );

  final template = File(
    p.join(root, 'tool', 'e2e', 'dio_cache_composition_test.dart.template'),
  );
  final testFile = File(p.join(fixture.path, 'test', 'composition_test.dart'));
  await testFile.parent.create(recursive: true);
  await testFile.writeAsString(
    (await template.readAsString()).replaceAll('{{app_name}}', 'e2e_dio_cache'),
  );

  if (!arguments.contains('--render-only')) {
    for (final command in const <List<String>>[
      <String>['pub', 'get'],
      <String>['test', 'test/composition_test.dart'],
    ]) {
      final result = await Process.run(
        'flutter',
        command,
        workingDirectory: fixture.path,
        runInShell: Platform.isWindows,
      );
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) {
        exitCode = result.exitCode;
        return;
      }
    }
  }
  stdout.writeln('Composed dio+http_cache fixture: ${fixture.path}');
}

Object? _fallbackAnswer(PromptSpec prompt) {
  return switch (prompt.type) {
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
