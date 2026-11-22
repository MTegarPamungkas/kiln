import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// Verifies real HTTP transport and policy adapters in one rendered app.
Future<void> main() async {
  final root = Directory.current;
  final fixture = Directory(
    p.join(root.path, '.dart_tool', 'verify_http_stack'),
  );
  final dependencies = <String, Object?>{
    'flutter': {'sdk': 'flutter'},
    'kiln_core': {
      'path': p
          .join(root.absolute.path, 'packages', 'kiln_core')
          .replaceAll('\\', '/'),
    },
  };
  for (final id in ['dio', 'rest_auth', 'http_retry', 'http_cache']) {
    final extension = Directory(p.join(root.path, 'extensions', id));
    final manifest = ExtensionManifest.parse(
      File(p.join(extension.path, 'extension.yaml')).readAsStringSync(),
      rootPath: extension.path,
    );
    final bundle = createBundle(Directory(p.join(extension.path, 'brick')));
    dependencies.addAll(manifest.dependencies);
    final files = await const BrickRenderer().render(
      bundle: bundle,
      vars: buildTemplateVars(
        extension: AvailableExtension(manifest: manifest, bundle: bundle),
        project: const {'name': 'verify_http_stack'},
        answers: const {'base_url': 'https://example.test'},
      ),
    );
    for (final file in files) {
      final target = File(p.join(fixture.path, file.relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(file.bytes);
    }
  }
  await File(p.join(fixture.path, 'pubspec.yaml')).writeAsString(
    jsonEncode({
      'name': 'verify_http_stack',
      'publish_to': 'none',
      'environment': {'sdk': '^3.13.0'},
      'dependencies': dependencies,
      'dev_dependencies': {
        'flutter_test': {'sdk': 'flutter'},
        'kiln_testing': {
          'path': p
              .join(root.absolute.path, 'packages', 'kiln_testing')
              .replaceAll('\\', '/'),
        },
      },
      'dependency_overrides': {
        'kiln_core': {
          'path': p
              .join(root.absolute.path, 'packages', 'kiln_core')
              .replaceAll('\\', '/'),
        },
      },
    }),
  );
  final test = File(p.join(fixture.path, 'test', 'http_stack_test.dart'));
  await test.parent.create(recursive: true);
  await test.writeAsString(
    await File(
      p.join(root.path, 'tool', 'fixtures', 'http_stack_test.dart.template'),
    ).readAsString(),
  );
  for (final command in <List<String>>[
    ['pub', 'get'],
    ['analyze'],
    ['test', 'test/http_stack_test.dart', '--reporter', 'expanded'],
  ]) {
    final result = await Process.run(
      'flutter',
      command,
      workingDirectory: fixture.path,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0 || command.first == 'test') {
      stdout.write(result.stdout);
      stderr.write(result.stderr);
    }
    if (result.exitCode != 0) {
      exitCode = result.exitCode;
      return;
    }
    stdout.writeln('HTTP stack: flutter ${command.join(' ')} passed.');
  }
}
