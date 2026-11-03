import 'dart:convert';
import 'dart:io';

import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  final outputIndex = arguments.indexOf('--output');
  final output = Directory(
    outputIndex >= 0 && outputIndex + 1 < arguments.length
        ? arguments[outputIndex + 1]
        : p.join(Directory.current.path, 'registry'),
  );

  final extensions = Directory(p.join(Directory.current.path, 'extensions'))
      .listSync()
      .whereType<Directory>()
      .where((directory) => File(p.join(directory.path, 'extension.yaml')).existsSync())
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
            await entity.copy(
              p.join(seeded.path, p.basename(entity.path)),
            );
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
        for (final file in Directory(p.join(target.path, 'archives'))
            .listSync()
            .whereType<File>()) {
          final actual = File(p.join(output.path, 'archives', p.basename(file.path)));
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
