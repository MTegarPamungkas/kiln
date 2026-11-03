import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'kiln_store_exception.dart';

/// Extracts extension archives while rejecting path traversal and links.
final class ArchiveUnpacker {
  const ArchiveUnpacker();

  static final RegExp _drivePattern = RegExp(r'^[a-zA-Z]:');

  /// Extracts [bytes] (a `.tar.gz`) into [target].
  ///
  /// Every entry is validated before anything is written. Absolute paths,
  /// drive letters, empty segments, `.`/`..` traversal, backslashes, symbolic
  /// links, hard links, and special files are rejected with code
  /// `store.unsafe_archive`.
  void extract(List<int> bytes, Directory target) {
    final Archive archive;
    try {
      final tarBytes = GZipDecoder().decodeBytes(bytes);
      archive = TarDecoder().decodeBytes(tarBytes, verify: true);
    } on Object catch (error) {
      throw KilnStoreException(
        'Archive is not a valid .tar.gz file: $error',
        code: 'store.invalid_archive',
        suggestion: 'Publish the extension again with ArchivePacker.',
      );
    }

    final rootPath = p.normalize(p.absolute(target.path));
    final pending = <_PendingEntry>[];
    for (final entry in archive) {
      final segments = _safeSegments(entry.name);
      if (entry.isSymbolicLink ||
          entry.isHardLink ||
          entry.symbolicLink != null) {
        throw KilnStoreException(
          'Archive entry "${entry.name}" is a link, which is not allowed.',
          code: 'store.unsafe_archive',
          suggestion: 'Repack the extension without symbolic or hard links.',
        );
      }
      if (!entry.isFile && !entry.isDirectory) {
        throw KilnStoreException(
          'Archive entry "${entry.name}" is not a regular file or directory.',
          code: 'store.unsafe_archive',
        );
      }
      final destination = p.normalize(
        p.joinAll(<String>[rootPath, ...segments]),
      );
      if (!p.isWithin(rootPath, destination)) {
        throw KilnStoreException(
          'Archive entry "${entry.name}" escapes the target directory.',
          code: 'store.unsafe_archive',
        );
      }
      pending.add(_PendingEntry(entry, destination));
    }

    target.createSync(recursive: true);
    for (final item in pending) {
      if (item.entry.isDirectory) {
        Directory(item.destination).createSync(recursive: true);
        continue;
      }
      final file = File(item.destination);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(item.entry.readBytes() ?? const <int>[]);
    }
  }

  static List<String> _safeSegments(String name) {
    if (name.isEmpty || name.contains('\u0000') || name.contains('\\')) {
      throw KilnStoreException(
        'Archive entry name "$name" is not a safe relative path.',
        code: 'store.unsafe_archive',
      );
    }
    if (name.startsWith('/') || _drivePattern.hasMatch(name)) {
      throw KilnStoreException(
        'Archive entry "$name" must be a relative path.',
        code: 'store.unsafe_archive',
      );
    }
    var trimmed = name;
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.isEmpty) {
      throw const KilnStoreException(
        'Archive contains an entry with an empty path.',
        code: 'store.unsafe_archive',
      );
    }
    final segments = <String>[];
    for (final segment in trimmed.split('/')) {
      if (segment == '.') {
        continue;
      }
      if (segment.isEmpty || segment == '..') {
        throw KilnStoreException(
          'Archive entry "$name" contains an unsafe path segment.',
          code: 'store.unsafe_archive',
        );
      }
      segments.add(segment);
    }
    if (segments.isEmpty) {
      throw KilnStoreException(
        'Archive entry "$name" resolves to an empty path.',
        code: 'store.unsafe_archive',
      );
    }
    return segments;
  }
}

final class _PendingEntry {
  const _PendingEntry(this.entry, this.destination);

  final ArchiveFile entry;
  final String destination;
}
