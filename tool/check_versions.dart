import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Guards the monorepo version story so it cannot silently drift again:
///
///   * every `packages/*` (and the workspace root) pubspec `version` must equal
///     the top heading of that package's `CHANGELOG.md`, when one exists;
///   * the `kiln_cli` `kilnVersion`/`kilnCoreVersion` constants must equal the
///     `kiln_cli` and `kiln_core` pubspec versions they advertise;
///   * every intra-workspace `^` dependency constraint must still allow the local
///     version of the package it points at, so a bump cannot leave a stale range.
///
/// Runs offline and deterministically. Exits non-zero with `--check` on drift.
Future<void> main(List<String> arguments) async {
  final json = arguments.contains('--json');
  final check = arguments.contains('--check');
  final root = Directory.current.absolute;

  final packages = <_Package>[];
  final rootSpec = File(p.join(root.path, 'pubspec.yaml'));
  if (!rootSpec.existsSync()) {
    stderr.writeln('No root pubspec.yaml found; run this tool from the repo root.');
    exitCode = 2;
    return;
  }
  packages.add(_Package.fromPubspec(root, rootSpec));

  final packagesDir = Directory(p.join(root.path, 'packages'));
  if (packagesDir.existsSync()) {
    for (final dir in packagesDir.listSync().whereType<Directory>()) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        packages.add(_Package.fromPubspec(dir, pubspec));
      }
    }
  }

  final byName = <String, String>{
    for (final package in packages) package.name: package.version,
  };

  final problems = <String>[];
  problems.addAll(_changelogDrift(packages));
  problems.addAll(_constantDrift(root, byName));
  problems.addAll(_constraintDrift(packages, byName));

  final versions = <String, String>{
    for (final package in packages)
      package.name: package.version,
  };

  if (json) {
    stdout.writeln(
      jsonEncode(<String, Object?>{
        'versions': versions,
        'problems': problems,
      }),
    );
  } else if (problems.isEmpty) {
    stdout.writeln(
      'Version story consistent across ${packages.length} workspace packages.',
    );
    for (final entry in versions.entries) {
      stdout.writeln('  ${entry.key}: ${entry.value}');
    }
  } else {
    stdout.writeln('Version drift detected:');
    for (final problem in problems) {
      stdout.writeln('  - $problem');
    }
  }

  if (check && problems.isNotEmpty) {
    exitCode = 1;
  }
}

List<String> _changelogDrift(List<_Package> packages) {
  final problems = <String>[];
  for (final package in packages) {
    final changelog = package.changelog;
    if (changelog == null || !changelog.existsSync()) {
      continue; // Packages with no changelog (e.g. kiln_lints) are exempt.
    }
    final heading = RegExp(
      r'^##\s+\[?(\d+\.\d+\.\d+)\]?',
      multiLine: true,
    ).firstMatch(changelog.readAsStringSync())?.group(1);
    if (heading == null) {
      problems.add(
        '${package.name}: CHANGELOG.md has no `## x.y.z` heading for ${package.version}.',
      );
    } else if (heading != package.version) {
      problems.add(
        '${package.name}: pubspec $package.version != CHANGELOG top $heading.',
      );
    }
  }
  return problems;
}

List<String> _constantDrift(Directory root, Map<String, String> byName) {
  final errors = <String>[];
  final versionFile = File(
    p.join(root.path, 'packages', 'kiln_cli', 'lib', 'src', 'version.dart'),
  );
  if (!versionFile.existsSync()) {
    return <String>['kiln_cli version.dart not found.'];
  }
  final source = versionFile.readAsStringSync();
  final cli = byName['kiln_cli'];
  final core = byName['kiln_core'];
  final cliConst =
      RegExp(r"kilnVersion\s*=\s*'([^']+)'").firstMatch(source)?.group(1);
  final coreConst =
      RegExp(r"kilnCoreVersion\s*=\s*'([^']+)'").firstMatch(source)?.group(1);
  if (cli != null && cliConst != cli) {
    errors.add('kiln_cli kilnVersion constant `$cliConst` != pubspec `$cli`.');
  }
  if (core != null && coreConst != core) {
    errors.add(
      'kiln_cli kilnCoreVersion constant `$coreConst` != kiln_core pubspec `$core`.',
    );
  }
  return errors;
}

List<String> _constraintDrift(List<_Package> packages, Map<String, String> byName) {
  final errors = <String>[];
  for (final package in packages) {
    final document = loadYaml(package.pubspec.readAsStringSync());
    if (document is! YamlMap) {
      continue;
    }
    for (final section in const ['dependencies', 'dev_dependencies']) {
      final map = document[section];
      if (map is! YamlMap) {
        continue;
      }
      for (final entry in map.entries) {
        final target = entry.key;
        if (!byName.containsKey(target) || target == package.name) {
          continue;
        }
        final value = entry.value;
        if (value is! String) {
          continue; // path: / sdk: / git: sources carry no version range.
        }
        final VersionConstraint constraint;
        try {
          constraint = VersionConstraint.parse(value.trim());
        } on FormatException {
          continue;
        }
        final localVersion = Version.parse(byName[target]!);
        if (!constraint.allows(localVersion)) {
          errors.add(
            '${package.name} pins $target `$value` but the workspace version is $localVersion.',
          );
        }
      }
    }
  }
  return errors;
}

final class _Package {
  const _Package({
    required this.name,
    required this.version,
    required this.directory,
    required this.pubspec,
    this.changelog,
  });

  factory _Package.fromPubspec(Directory directory, File pubspec) {
    final document = loadYaml(pubspec.readAsStringSync());
    final name = document is YamlMap ? '${document['name']}' : p.basename(directory.path);
    final version = document is YamlMap ? '${document['version']}' : '';
    final changelog = File(p.join(directory.path, 'CHANGELOG.md'));
    return _Package(
      name: name,
      version: version,
      directory: directory,
      pubspec: pubspec,
      changelog: changelog.existsSync() ? changelog : null,
    );
  }

  final String name;
  final String version;
  final Directory directory;
  final File pubspec;
  final File? changelog;
}
