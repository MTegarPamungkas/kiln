import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'kiln_store_exception.dart';

/// Extracts extension archives while rejecting path traversal and links.
final class ArchiveUnpacker {
  const ArchiveUnpacker({
    this.maxCompressedBytes = 50 * 1024 * 1024,
    this.maxExpandedBytes = 100 * 1024 * 1024,
    this.maxEntryBytes = 50 * 1024 * 1024,
    this.maxEntries = 2000,
  });

  final int maxCompressedBytes;
  final int maxExpandedBytes;
  final int maxEntryBytes;
  final int maxEntries;

  static final RegExp _drivePattern = RegExp(r'^[a-zA-Z]:');

  void _requireBudget(bool ok, String message) {
    if (!ok) {
      throw KilnStoreException(
        message,
        code: 'store.archive_too_large',
        suggestion: 'Publish a smaller extension archive.',
      );
    }
  }

  /// Extracts [bytes] (a `.tar.gz`) into [target].
  ///
  /// Every entry is validated before anything is written. Absolute paths,
  /// drive letters, empty segments, `.`/`..` traversal, backslashes, symbolic
  /// links, hard links, and special files are rejected with code
  /// `store.unsafe_archive`.
  void extract(List<int> bytes, Directory target) {
    _requireBudget(
      bytes.length <= maxCompressedBytes,
      'Archive is ${bytes.length} bytes; the limit is $maxCompressedBytes.',
    );
    final Archive archive;
    try {
      // Bound inflated bytes before the tar parser can allocate every entry.
      // Tar adds a header and up to one padding block per file.
      final sink = _BoundedArchiveSink(
        maxExpandedBytes + (maxEntries + 1) * 1024,
      );
      final decoder = gzip.decoder.startChunkedConversion(sink);
      for (var offset = 0; offset < bytes.length; offset += 4096) {
        final end = offset + 4096 < bytes.length ? offset + 4096 : bytes.length;
        decoder.add(bytes.sublist(offset, end));
      }
      decoder.close();
      final tarBytes = sink.bytes.takeBytes();
      archive = TarDecoder().decodeBytes(tarBytes, verify: true);
    } on KilnStoreException {
      rethrow;
    } on Object catch (error) {
      throw KilnStoreException(
        'Archive is not a valid .tar.gz file: $error',
        code: 'store.invalid_archive',
        suggestion: 'Publish the extension again with ArchivePacker.',
      );
    }

    _requireBudget(
      archive.length <= maxEntries,
      'Archive has ${archive.length} entries; the limit is $maxEntries.',
    );
    var expandedBytes = 0;
    final rootPath = p.normalize(p.absolute(target.path));
    final pending = <_PendingEntry>[];
    for (final entry in archive) {
      if (entry.isFile) {
        _requireBudget(
          entry.size <= maxEntryBytes,
          'Archive entry "${entry.name}" is ${entry.size} bytes; the limit is $maxEntryBytes.',
        );
        expandedBytes += entry.size;
        _requireBudget(
          expandedBytes <= maxExpandedBytes,
          'Archive expands to more than $maxExpandedBytes bytes.',
        );
      }
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

final class _BoundedArchiveSink implements Sink<List<int>> {
  _BoundedArchiveSink(this.limit);
  final int limit;
  final BytesBuilder bytes = BytesBuilder(copy: false);

  @override
  void add(List<int> data) {
    if (bytes.length + data.length > limit) {
      throw const KilnStoreException(
        'The decompressed archive exceeds its size budget.',
        code: 'store.archive_too_large',
      );
    }
    bytes.add(data);
  }

  @override
  void close() {}
}

final class _PendingEntry {
  const _PendingEntry(this.entry, this.destination);

  final ArchiveFile entry;
  final String destination;
}
