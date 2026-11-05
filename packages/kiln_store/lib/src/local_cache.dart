import 'dart:io';

import 'package:path/path.dart' as p;

import 'registry_index.dart';

/// On-disk cache for the registry index and downloaded archives.
///
/// Layout:
/// ```text
/// <root>/index.json
/// <root>/archives/<id>-<version>.tgz
/// ```
final class LocalCache {
  LocalCache(this.root);

  final Directory root;

  File get indexFile => File(p.join(root.path, 'index.json'));

  File archiveFile(String id, String version) =>
      File(p.join(root.path, 'archives', '$id-$version.tgz'));

  /// Reads the cached index, or `null` when the cache is empty.
  Future<RegistryIndex?> readIndex() async {
    if (!await indexFile.exists()) {
      return null;
    }
    return RegistryIndex.parse(await indexFile.readAsString());
  }

  /// Writes [index] to the cache, replacing any previous copy.
  void writeIndex(RegistryIndex index) {
    indexFile.parent.createSync(recursive: true);
    indexFile.writeAsStringSync(index.encode());
  }

  /// Reads a cached archive, or `null` when it was never downloaded.
  Future<List<int>?> readArchive(String id, String version) async {
    final file = archiveFile(id, version);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  /// Writes an archive to the cache.
  void writeArchive(String id, String version, List<int> bytes) {
    final file = archiveFile(id, version);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }

  /// Deletes every cached index and archive and recreates the cache root.
  void clear() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
    root.createSync(recursive: true);
  }
}
