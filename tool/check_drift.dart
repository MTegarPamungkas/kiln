import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> arguments) async {
  final json = arguments.contains('--json');
  final check = arguments.contains('--check');
  final includeMinor = arguments.contains('--minor');
  final root = Directory.current;
  final packages = <String, String>{};

  for (final directory in Directory(
    p.join(root.path, 'extensions'),
  ).listSync().whereType<Directory>()) {
    final manifestFile = File(p.join(directory.path, 'extension.yaml'));
    if (!manifestFile.existsSync()) {
      continue;
    }
    final document = loadYaml(manifestFile.readAsStringSync());
    if (document is! YamlMap) {
      continue;
    }
    for (final section in const <String>['dependencies', 'dev_dependencies']) {
      final dependencies = document[section];
      if (dependencies is! YamlMap) {
        continue;
      }
      for (final entry in dependencies.entries) {
        final value = entry.value;
        if (value is String && value.trim().isNotEmpty) {
          packages.putIfAbsent('${entry.key}', () => value.trim());
        }
      }
    }
  }

  final client = http.Client();
  final drift = <Map<String, Object?>>[];
  final unavailable = <String>[];
  try {
    final entries = packages.entries.toList(growable: false);
    const batchSize = 8;
    for (var i = 0; i < entries.length; i += batchSize) {
      final batch = entries.sublist(
        i,
        i + batchSize > entries.length ? entries.length : i + batchSize,
      );
      final results = await Future.wait(
        batch.map(
          (entry) async =>
              (entry: entry, latest: await _latestVersion(client, entry.key)),
        ),
      );
      for (final result in results) {
        final entry = result.entry;
        final latest = result.latest;
        if (latest == null) {
          unavailable.add(entry.key);
          continue;
        }
        final VersionConstraint constraint;
        try {
          constraint = VersionConstraint.parse(entry.value);
        } on FormatException {
          continue;
        }
        final isMajorDrift = !constraint.allows(latest);
        final isMinorDrift =
            includeMinor &&
            !isMajorDrift &&
            entry.value.startsWith('^') &&
            constraint is VersionRange &&
            constraint.min != null &&
            constraint.min! < latest;
        if (isMajorDrift || isMinorDrift) {
          drift.add(<String, Object?>{
            'package': entry.key,
            'constraint': entry.value,
            'latest': latest.toString(),
            'kind': isMajorDrift ? 'major' : 'minor',
          });
        }
      }
    }
  } finally {
    client.close();
  }
  drift.sort(
    (left, right) => '${left['package']}'.compareTo('${right['package']}'),
  );

  if (json) {
    stdout.writeln(
      jsonEncode(<String, Object?>{
        'checked': packages.length,
        'drift': drift,
        'unavailable': unavailable,
      }),
    );
  } else if (drift.isEmpty) {
    stdout.writeln('No dependency drift across ${packages.length} packages.');
  } else {
    stdout.writeln('Dependency drift:');
    for (final entry in drift) {
      stdout.writeln(
        '  ${entry['package']} ${entry['constraint']} -> ${entry['latest']} (${entry['kind']})',
      );
    }
  }
  if (check && drift.isNotEmpty) {
    exitCode = 1;
  }
}

Future<Version?> _latestVersion(http.Client client, String package) async {
  final response = await client.get(
    Uri.parse('https://pub.dev/api/packages/$package'),
  );
  if (response.statusCode != 200) {
    return null;
  }
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return null;
    }
    final latest = decoded['latest'];
    if (latest is! Map) {
      return null;
    }
    final version = latest['version'];
    return version is String ? Version.parse(version) : null;
  } on Object {
    return null;
  }
}
