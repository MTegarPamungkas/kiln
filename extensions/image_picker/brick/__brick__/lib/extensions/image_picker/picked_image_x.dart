import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';

/// Convenience helpers on [PickedImage].
extension PickedImageX on PickedImage {
  /// Builds an in-memory image provider from the picked bytes.
  ///
  /// Picker implementations always read the bytes, so this works on mobile and
  /// web without touching the platform file system.
  ImageProvider toImageProvider() {
    final data = bytes;
    if (data == null) {
      throw const Failure(
        code: FailureCode.mediaInvalid,
        message: 'Gambar membutuhkan byte untuk ditampilkan.',
        kind: FailureKind.media,
      );
    }
    return MemoryImage(Uint8List.fromList(data));
  }

  /// Human readable size, for example "1,2 MB".
  String? get readableSize {
    final size = sizeBytes ?? bytes?.length;
    if (size == null) {
      return null;
    }
    if (size < 1024) {
      return '$size B';
    }
    final kb = size / 1024;
    if (kb < 1024) {
      return '${_format(kb)} KB';
    }
    final mb = kb / 1024;
    if (mb < 1024) {
      return '${_format(mb)} MB';
    }
    return '${_format(mb / 1024)} GB';
  }
}

String _format(double value) {
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.truncateToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}
