import 'dart:io';

import 'package:path/path.dart' as p;

import '../../kiln_exception.dart';

/// A portable, root-relative file path. Transaction paths use `/` on every OS.
/// Symlinks (including dangling links and junctions) are deliberately rejected:
/// snapshots cannot safely preserve both link identity and target ownership.
final class RootPath {
  const RootPath(this.root);

  final Directory root;

  static void validateRelative(String path) {
    final segments = path.split('/');
    if (path.isEmpty ||
        path.contains('\\') ||
        path.contains(':') ||
        path.contains('\x00') ||
        p.posix.isAbsolute(path) ||
        p.windows.isAbsolute(path) ||
        segments.any((part) =>
            part.isEmpty || part == '.' || part == '..' ||
            part.endsWith('.') || part.endsWith(' '))) {
      throw KilnException('Unsafe project path: "$path"', code: 'path.unsafe');
    }
  }

  static void validateId(String id) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      throw KilnException('Unsafe transaction id: "$id"', code: 'path.unsafe');
    }
  }

  String resolve(String relative) {
    validateRelative(relative);
    final absoluteRoot = p.normalize(root.absolute.path);
    var current = absoluteRoot;
    for (final part in relative.split('/')) {
      current = p.join(current, part);
      final type = FileSystemEntity.typeSync(current, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw KilnException('Symlink in project path: "$relative"',
            code: 'path.unsafe');
      }
      // Check real existing ancestors as well (e.g. Windows junctions).
      if (type != FileSystemEntityType.notFound) {
        final real = File(current).resolveSymbolicLinksSync();
        final realRoot = root.resolveSymbolicLinksSync();
        if (!p.isWithin(realRoot, real)) {
          throw KilnException('Path escapes project root: "$relative"',
              code: 'path.unsafe');
        }
      }
    }
    if (!p.isWithin(absoluteRoot, current)) {
      throw KilnException('Path escapes project root: "$relative"',
          code: 'path.unsafe');
    }
    return current;
  }
}
