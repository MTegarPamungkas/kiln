import 'package:kiln_core/kiln_core.dart';

import 'image_dimensions.dart';
import 'media_picker_config.dart';
import 'mime_sniffer.dart';

/// Rejects images above the size limit, outside the allowed types, or larger
/// than the configured decoded dimension limits.
///
/// The dimension check reads the encoded header only, so a file that declares a
/// huge bitmap is rejected before any decoder allocates it. When the header
/// cannot be measured (truncated or an unknown variant) the check is skipped:
/// such a payload cannot be decoded into a bitmap either.
final class ImageValidator {
  const ImageValidator({this.config = MediaPickerConfig.defaults});

  final MediaPickerConfig config;

  /// Returns the detected mime type or throws Failure(validation).
  String ensureValid(PickedImage image) {
    final size = image.sizeBytes;
    if ((size != null && (size < 0 || size > config.maxBytes)) ||
        (image.bytes?.length ?? 0) > config.maxBytes) {
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
    if (bytes != null) {
      _ensureDimensions(ImageDimensionsReader.read(bytes));
    }
    return mime;
  }

  void _ensureDimensions(ImageDimensions? dimensions) {
    if (dimensions == null) {
      return;
    }
    if (dimensions.width <= config.maxDecodedWidth &&
        dimensions.height <= config.maxDecodedHeight &&
        dimensions.pixels <= config.maxDecodedPixels) {
      return;
    }
    throw Failure(
      code: FailureCode.mediaInvalid,
      message:
          'Image ${dimensions.width}x${dimensions.height} '
          '(${dimensions.pixels} pixels) exceeds the configured decode limit.',
      kind: FailureKind.validation,
      details: <String, Object?>{
        'width': dimensions.width,
        'height': dimensions.height,
        'pixels': dimensions.pixels,
        'max_width': config.maxDecodedWidth,
        'max_height': config.maxDecodedHeight,
        'max_pixels': config.maxDecodedPixels,
      },
    );
  }

  Failure _invalid(String message) {
    return Failure(
      code: FailureCode.mediaInvalid,
      message: message,
      kind: FailureKind.validation,
    );
  }
}
