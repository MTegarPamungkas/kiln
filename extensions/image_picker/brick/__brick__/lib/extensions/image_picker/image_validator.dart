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
        'Image size $size bytes exceeds the ${config.maxBytes} byte limit.',
      );
    }
    final bytes = image.bytes;
    final mime = bytes != null ? MimeSniffer.detect(bytes) : image.mimeType;
    if (mime == null) {
      throw _invalid('The image type could not be detected.');
    }
    if (!config.allowedTypes.contains(mime)) {
      throw _invalid('Type $mime is not allowed.');
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
