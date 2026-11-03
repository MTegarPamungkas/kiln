import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> arguments) async {
  final json = arguments.contains('--json');
  final check = arguments.contains('--check');
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
    final dependencies = document['dependencies'];
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

  final client = http.Client();
  final drift = <Map<String, Object?>>[];
  final unavailable = <String>[];
  try {
    for (final entry in packages.entries) {
      final latest = await _latestVersion(client, entry.key);
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
      if (!constraint.allows(latest)) {
        drift.add(<String, Object?>{
          'package': entry.key,
          'constraint': entry.value,
          'latest': latest.toString(),
        });
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
        '  ${entry['package']} ${entry['constraint']} -> ${entry['latest']}',
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
