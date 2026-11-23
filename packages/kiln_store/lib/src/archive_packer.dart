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

  /// The extension's own suite is development-only: installing an extension
  /// reads `extension.yaml`, `brick/`, and `docs/` only. Shipping it made every
  /// test-only edit change the archive digest, which the immutable-version
  /// guard then rejects for an already-published version. Only the root
  /// `test/` is excluded; `brick/__brick__/test/` is the suite rendered into
  /// user applications and must stay.
  static const String _excludedRootDirectory = 'test';

  /// Packs [extensionRoot] into a gzip-compressed tar archive.
  ///
  /// Skips `.dart_tool`, `.git`, `build`, `.kiln`, the root `test/` directory,
  /// and generated `.tgz` or `.tar.gz` archives. Symbolic links are not
  /// followed.
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
    // Use the pure-Dart GZip encoder rather than dart:io's native ZLibCodec:
    // native zlib writes a platform-specific OS header byte (10 on Windows vs
    // 3 on Linux) and can vary across system zlib builds, breaking cross-OS
    // `registry.dart --check`. Zero the RFC 1952 MTIME header (bytes 4..7)
    // because GZipEncoderWeb stamps DateTime.now() there.
    final gzip = Uint8List.fromList(
      const GZipEncoderWeb().encodeBytes(tar, level: 9),
    );
    if (gzip.length >= 10) {
      gzip[4] = 0;
      gzip[5] = 0;
      gzip[6] = 0;
      gzip[7] = 0;
    }
    return gzip;
  }

  static bool _shouldSkip(String relativePath) {
    final segments = relativePath.split('/');
    // Only the extension's own root-level suite; a nested test/ directory is
    // part of the rendered brick.
    if (segments.first == _excludedRootDirectory && segments.length > 1) {
      return true;
    }
    for (final segment in segments) {
      if (_excludedDirectories.contains(segment)) {
        return true;
      }
    }
    final name = segments.last.toLowerCase();
    return name.endsWith('.tgz') || name.endsWith('.tar.gz');
  }
}
