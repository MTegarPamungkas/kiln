import 'dart:io';

import 'package:path/path.dart' as p;

/// An in-memory view of project files touched by native patches.
final class ProjectFiles {
  ProjectFiles(this.projectRoot);

  final Directory projectRoot;
  final Map<String, String?> _changes = <String, String?>{};

  String? read(String relativePath) {
    final path = _normalize(relativePath);
    if (_changes.containsKey(path)) {
      return _changes[path];
    }
    final file = File(p.join(projectRoot.path, path));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  bool exists(String relativePath) => read(relativePath) != null;

  void write(String relativePath, String content) {
    _changes[_normalize(relativePath)] = content;
  }

  void delete(String relativePath) {
    _changes[_normalize(relativePath)] = null;
  }

  Map<String, String?> get changes =>
      Map<String, String?>.unmodifiable(_changes);

  String _normalize(String path) => path.replaceAll('\\', '/');
}

/// One idempotent native file patch.
abstract interface class Patch {
  String get id;

  String get description;

  void apply(ProjectFiles files);

  void revert(ProjectFiles files);
}
