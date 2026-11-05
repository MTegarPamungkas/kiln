import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'kiln_store_exception.dart';

/// Creates deterministic `.tar.gz` archives from extension directories.
///
/// Paths are stored as relative POSIX paths, entries are sorted by name, and
/// timestamps/modes are fixed so packing the same tree twice yields identical
/// bytes. That matters for registry `--check` runs.
final class ArchivePacker {
  const ArchivePacker();

  static const Set<String> _excludedDirectories = <String>{
    '.dart_tool',
    '.git',
    'build',
    '.kiln',
  };

  /// Packs [extensionRoot] into a gzip-compressed tar archive.
  ///
  /// Skips `.dart_tool`, `.git`, `build`, `.kiln`, and generated `.tgz` or
  /// `.tar.gz` archives. Symbolic links are not followed.
  Uint8List pack(Directory extensionRoot) {
    if (!extensionRoot.existsSync()) {
      throw KilnStoreException(
        'Extension directory does not exist: ${extensionRoot.path}',
        code: 'store.pack_missing_root',
      );
    }

    final relativePaths = <String>[];
    for (final entity in extensionRoot.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }
      final relative = p.posix.joinAll(
        p.split(p.relative(entity.path, from: extensionRoot.path)),
      );
      if (_shouldSkip(relative)) {
        continue;
      }
      relativePaths.add(relative);
    }
    relativePaths.sort();

    final archive = Archive();
    for (final relative in relativePaths) {
      final bytes = File(
        p.join(extensionRoot.path, p.joinAll(relative.split('/'))),
      ).readAsBytesSync();
      final entry = ArchiveFile.bytes(relative, bytes)
        ..lastModTime = 0
        ..creationTime = 0
        ..ownerId = 0
        ..groupId = 0;
      archive.add(entry);
    }

    final tar = TarEncoder().encodeBytes(archive);
    return GZipEncoder().encodeBytes(tar, level: 9);
  }

  static bool _shouldSkip(String relativePath) {
    final segments = relativePath.split('/');
    for (final segment in segments) {
      if (_excludedDirectories.contains(segment)) {
        return true;
      }
    }
    final name = segments.last.toLowerCase();
    return name.endsWith('.tgz') || name.endsWith('.tar.gz');
  }
}
