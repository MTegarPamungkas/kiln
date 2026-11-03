import 'dart:io';

import 'package:path/path.dart' as p;

const Set<String> _skipDirectories = <String>{
  '.dart_tool',
  '.git',
  'build',
  'docs_api',
  '_wip',
};

void main(List<String> arguments) {
  final check = arguments.contains('--check');
  final root = Directory.current.absolute;
  final files = <File>[
    File(p.join(root.path, 'README.md')),
    ..._markdownIn(Directory(p.join(root.path, 'docs'))),
    ..._markdownIn(Directory(p.join(root.path, 'registry'))),
    for (final directory in <Directory>[
      Directory(p.join(root.path, 'packages')),
      Directory(p.join(root.path, 'extensions')),
    ])
      ..._readmes(directory),
  ];

  final missing = <String>[];
  final unbalanced = <String>[];
  for (final file in files) {
    if (!file.existsSync()) {
      continue;
    }
    final source = file.readAsStringSync();
    final relative = p.relative(file.path, from: root.path);
    if (_fenceCount(source).isOdd) {
      unbalanced.add(relative);
    }
    for (final target in _localLinks(source)) {
      final path = _localPath(target);
      if (path == null) {
        continue;
      }
      final resolved = p.normalize(
        p.isAbsolute(path)
            ? p.join(root.path, path.substring(1))
            : p.join(file.parent.path, path),
      );
      if (!FileSystemEntity.isFileSync(resolved) &&
          !Directory(resolved).existsSync()) {
        missing.add('$relative -> $target');
      }
    }
  }

  if (missing.isEmpty && unbalanced.isEmpty) {
    stdout.writeln('Docs are consistent (${files.length} files).');
    return;
  }
  for (final entry in missing) {
    stderr.writeln('missing link: $entry');
  }
  for (final entry in unbalanced) {
    stderr.writeln('unbalanced code fence: $entry');
  }
  if (check) {
    exitCode = 1;
  }
}

List<File> _markdownIn(Directory directory) {
  if (!directory.existsSync()) {
    return const <File>[];
  }
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .where((file) {
        final relative = p
            .relative(file.path, from: directory.path)
            .replaceAll(r'\', '/');
        return !_skipDirectories.any(
          (skip) => relative == skip || relative.startsWith('$skip/'),
        );
      })
      .toList(growable: false);
}

List<File> _readmes(Directory directory) {
  if (!directory.existsSync()) {
    return const <File>[];
  }
  return <File>[
    for (final entry in directory.listSync().whereType<Directory>())
      if (File(p.join(entry.path, 'README.md')).existsSync())
        File(p.join(entry.path, 'README.md')),
  ];
}

Iterable<String> _localLinks(String source) sync* {
  var inFence = false;
  for (final line in source.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) {
      continue;
    }
    for (final match in RegExp(
      r'!?\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)',
    ).allMatches(line)) {
      yield match.group(1)!;
    }
  }
}

String? _localPath(String target) {
  if (target.startsWith('#')) {
    return null;
  }
  final uri = Uri.tryParse(target);
  if (uri == null || uri.hasScheme || target.startsWith('mailto:')) {
    return null;
  }
  final path = target.split('#').first.split('?').first;
  return path.isEmpty ? null : Uri.decodeFull(path);
}

int _fenceCount(String source) {
  return source
      .split('\n')
      .where((line) => line.trimLeft().startsWith('```'))
      .length;
}
