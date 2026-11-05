import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// One rendered file, with its path relative to the project root.
final class RenderedFile {
  const RenderedFile({required this.relativePath, required this.bytes});

  final String relativePath;
  final List<int> bytes;

  int get size => bytes.length;
}

/// Renders a Mason bundle into a temporary directory and returns its files.
///
/// The installer never lets Mason write directly into a user project: it first
/// computes every rendered file, then applies collision rules and a
/// transaction.
final class BrickRenderer {
  const BrickRenderer();

  Future<List<RenderedFile>> render({
    required MasonBundle bundle,
    required Map<String, dynamic> vars,
  }) async {
    if (bundle.files.isEmpty) {
      return const <RenderedFile>[];
    }
    final temp = await Directory.systemTemp.createTemp('kiln_render_');
    final brickDir = await Directory.systemTemp.createTemp('kiln_brick_');
    try {
      unpackBundle(bundle, brickDir);
      final generator = await MasonGenerator.fromBrick(
        Brick.path(brickDir.path),
      );
      await generator.generate(
        DirectoryGeneratorTarget(temp),
        vars: vars,
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      final files = <RenderedFile>[];
      await for (final entity in temp.list(recursive: true)) {
        if (entity is! File) {
          continue;
        }
        final relative = p.relative(entity.path, from: temp.path);
        files.add(
          RenderedFile(
            relativePath: relative.replaceAll('\\', '/'),
            bytes: await entity.readAsBytes(),
          ),
        );
      }
      files.sort(
        (left, right) => left.relativePath.compareTo(right.relativePath),
      );
      return List<RenderedFile>.unmodifiable(files);
    } finally {
      if (temp.existsSync()) {
        await temp.delete(recursive: true);
      }
      if (brickDir.existsSync()) {
        await brickDir.delete(recursive: true);
      }
    }
  }
}
