import 'dart:convert';
import 'dart:io';

import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  final outputIndex = arguments.indexOf('--output');
  final baselineIndex = arguments.indexOf('--baseline');
  if (baselineIndex == arguments.length - 1 && baselineIndex >= 0) {
    stderr.writeln('Pass a registry index file after --baseline.');
    exitCode = 64;
    return;
  }
  final output = Directory(
    outputIndex >= 0 && outputIndex + 1 < arguments.length
        ? arguments[outputIndex + 1]
        : p.join(Directory.current.path, 'registry'),
  );

  final extensions =
      Directory(p.join(Directory.current.path, 'extensions'))
          .listSync()
          .whereType<Directory>()
          .where(
            (directory) =>
                File(p.join(directory.path, 'extension.yaml')).existsSync(),
          )
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  if (extensions.isEmpty) {
    stderr.writeln('No extensions found.');
    exitCode = 1;
    return;
  }

  final target = check
      ? await Directory.systemTemp.createTemp('kiln_registry_check_')
      : output;
  try {
    if (check) {
      // Seed the temp registry with the current one so published version
      // history is preserved; otherwise every new version fails the check.
      final index = File(p.join(output.path, 'index.json'));
      if (index.existsSync()) {
        await index.copy(p.join(target.path, 'index.json'));
      }
      final archives = Directory(p.join(output.path, 'archives'));
      if (archives.existsSync()) {
        final seeded = Directory(p.join(target.path, 'archives'));
        await seeded.create(recursive: true);
        await for (final entity in archives.list()) {
          if (entity is File) {
            await entity.copy(p.join(seeded.path, p.basename(entity.path)));
          }
        }
      }
    }

    final publisher = Publisher();
    for (final extension in extensions) {
      await publisher.publish(
        extensionRoot: extension,
        registryRoot: target,
        force: true,
      );
    }

    _verifyPublishedArchives(target);
    if (baselineIndex >= 0) {
      final baseline = File(arguments[baselineIndex + 1]);
      _verifyVersionHistory(baseline, target);
    }
    if (check) {
      final expectedIndex = _normalized(
        File(p.join(target.path, 'index.json')).readAsStringSync(),
      );
      final actualIndexFile = File(p.join(output.path, 'index.json'));
      final actualIndex = actualIndexFile.existsSync()
          ? _normalized(actualIndexFile.readAsStringSync())
          : null;
      var changed = expectedIndex != actualIndex;
      if (!changed) {
        for (final file in Directory(
          p.join(target.path, 'archives'),
        ).listSync().whereType<File>()) {
          final actual = File(
            p.join(output.path, 'archives', p.basename(file.path)),
          );
          if (!actual.existsSync() ||
              !_sameBytes(file.readAsBytesSync(), actual.readAsBytesSync())) {
            changed = true;
            stderr.writeln('out of date: ${actual.path}');
          }
        }
      }
      if (changed) {
        stderr.writeln('registry/index.json or archives are out of date');
        exitCode = 1;
      }
      return;
    }

    stdout.writeln('wrote ${p.join(output.path, 'index.json')}');
  } finally {
    if (check && target.existsSync()) {
      await target.delete(recursive: true);
    }
  }
}

// The retired Neon distribution remains available at its historical URL.
const _retainedArchives = {'neon-0.1.0.tgz'};

void _verifyPublishedArchives(Directory registry) {
  final index = _readIndex(registry);
  final expected = <String>{..._retainedArchives};
  final archives = Directory(p.join(registry.path, 'archives'));
  for (final extension in index.extensions) {
    for (final version in extension.versions) {
      final name = '${extension.id}-${version.version}.tgz';
      if (p.posix.basename(name) != name || p.windows.basename(name) != name) {
        throw StateError('Invalid registry archive name: $name');
      }
      expected.add(name);
      final file = File(p.join(archives.path, name));
      const ChecksumVerifier().verify(file.readAsBytesSync(), version.sha256);
    }
  }
  final orphaned = archives
      .listSync()
      .whereType<File>()
      .map((file) => p.basename(file.path))
      .where((name) => !expected.contains(name));
  if (orphaned.isNotEmpty) {
    throw StateError('Unreferenced registry archives: ${orphaned.join(', ')}');
  }
}

RegistryIndex _readIndex(Directory registry) => RegistryIndex.parse(
  File(p.join(registry.path, 'index.json')).readAsStringSync(),
);

void _verifyVersionHistory(File baseline, Directory registry) {
  final current = _readIndex(registry);
  for (final extension in RegistryIndex.parse(
    baseline.readAsStringSync(),
  ).extensions) {
    for (final old in extension.versions) {
      final next = current.find(extension.id)?.findVersion(old.version);
      if (next?.sha256 != old.sha256 || next?.url != old.url) {
        throw StateError(
          'Published version ${extension.id} ${old.version} changed.',
        );
      }
    }
  }
}

String _normalized(String source) {
  final decoded = jsonDecode(source) as Map<String, Object?>;
  decoded.remove('generated_at');
  return jsonEncode(decoded);
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
