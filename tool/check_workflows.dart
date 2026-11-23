import 'dart:io';

import 'package:yaml/yaml.dart';

/// Validates the CI workflows and the extension matrix source of truth.
void main() {
  final workflows = Directory('.github/workflows')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.yaml') || file.path.endsWith('.yml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var failures = 0;
  for (final file in workflows) {
    try {
      final document = loadYaml(file.readAsStringSync());
      if (document is! YamlMap) {
        stderr.writeln('${file.path}: not a YAML map');
        failures++;
        continue;
      }
      for (final key in const ['name', 'on', 'jobs']) {
        if (!document.containsKey(key)) {
          stderr.writeln('${file.path}: missing "$key"');
          failures++;
        }
      }
      final jobs = document['jobs'];
      if (jobs is YamlMap) {
        for (final entry in jobs.entries) {
          final job = entry.value;
          if (job is! YamlMap || !job.containsKey('runs-on')) {
            stderr.writeln('${file.path}: job "${entry.key}" has no runs-on');
            failures++;
          }
        }
      }
    } on YamlException catch (error) {
      stderr.writeln('${file.path}: ${error.message}');
      failures++;
    }
  }

  // The extension matrix must be derived, not hand-listed, so a new extension
  // cannot be added without its suite running in CI.
  final extensions = File('.github/workflows/extensions.yaml');
  final source = extensions.existsSync() ? extensions.readAsStringSync() : '';
  if (!source.contains(r'fromJSON(needs.discover.outputs.extensions)')) {
    stderr.writeln(
      'extensions.yaml: the matrix must come from the discover job',
    );
    failures++;
  }
  if (source.contains(RegExp(r'^\s+- [a-z_]+$', multiLine: true))) {
    stderr.writeln('extensions.yaml: the matrix still lists extensions by hand');
    failures++;
  }

  // Every extension directory must expose a manifest and a test suite.
  for (final directory in Directory('extensions').listSync().whereType<Directory>()) {
    final name = directory.path.split(Platform.pathSeparator).last;
    for (final required in const ['extension.yaml', 'pubspec.yaml']) {
      if (!File('${directory.path}/$required').existsSync()) {
        stderr.writeln('extensions/$name: missing $required');
        failures++;
      }
    }
    if (!Directory('${directory.path}/test').existsSync()) {
      stderr.writeln('extensions/$name: missing test/');
      failures++;
    }
  }

  if (failures > 0) {
    stderr.writeln('$failures workflow problem(s).');
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Checked ${workflows.length} workflows and '
    '${Directory('extensions').listSync().whereType<Directory>().length} extensions.',
  );
}
