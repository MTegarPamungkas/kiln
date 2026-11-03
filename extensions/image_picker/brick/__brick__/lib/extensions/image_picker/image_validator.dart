import 'package:kiln_core/kiln_core.dart';

import 'media_picker_config.dart';
import 'mime_sniffer.dart';

/// Rejects images above the size limit or outside the allowed types.
final class ImageValidator {
  const ImageValidator({this.config = MediaPickerConfig.defaults});

  final MediaPickerConfig config;

  /// Returns the detected mime type or throws Failure(validation).
  String ensureValid(PickedImage image) {
    final size = image.sizeBytes ?? image.bytes?.length;
    if (size != null && size > config.maxBytes) {
      throw _invalid(
        'Ukuran gambar $size byte melebihi batas ${config.maxBytes} byte.',
      );
    }
    final bytes = image.bytes;
    final mime = bytes != null ? MimeSniffer.detect(bytes) : image.mimeType;
    if (mime == null) {
      throw _invalid('Tipe gambar tidak dikenali.');
    }
    if (!config.allowedTypes.contains(mime)) {
      throw _invalid('Tipe $mime tidak diizinkan.');
    }
    return mime;
  }

  Failure _invalid(String message) {
    return Failure(
      code: FailureCode.mediaInvalid,
      message: message,
      kind: FailureKind.validation,
    );
  }
}
