import 'package:kiln_core/kiln_core.dart';

import 'image_validator.dart';

/// Turns a [PickedImage] into a [FileUpload] for [FileStorage].
final class PickedImageUploadAdapter {
  const PickedImageUploadAdapter({
    required this.storage,
    this.directory = 'images',
    this.validator = const ImageValidator(),
  });

  final FileStorage storage;
  final String directory;
  final ImageValidator validator;

  Future<StoredFile> upload(
    PickedImage image, {
    ProgressCallback? onProgress,
    Map<String, String> metadata = const <String, String>{},
  }) {
    final bytes = image.bytes;
    if (bytes == null) {
      throw const Failure(
        code: FailureCode.mediaInvalid,
        message: 'Image bytes are not available for upload.',
        kind: FailureKind.validation,
      );
    }
    if (image.name.isEmpty || image.name == '.' || image.name == '..' ||
        image.name.contains('/') || image.name.contains('\\')) {
      throw const Failure(code: FailureCode.mediaInvalid,
        message: 'The image name must be a file name without path segments.',
        kind: FailureKind.validation);
    }
    final mime = validator.ensureValid(image);
    return storage.upload(
      FileUpload(
        path: '$directory/${image.name}',
        bytes: bytes,
        contentType: mime,
        metadata: metadata,
      ),
      onProgress: onProgress,
    );
  }
}
