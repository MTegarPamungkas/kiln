import 'package:kiln_core/kiln_core.dart';

/// Turns a [PickedImage] into a [FileUpload] for [FileStorage].
final class PickedImageUploadAdapter {
  const PickedImageUploadAdapter({
    required this.storage,
    this.directory = 'images',
  });

  final FileStorage storage;
  final String directory;

  Future<StoredFile> upload(
    PickedImage image, {
    ProgressCallback? onProgress,
    Map<String, String> metadata = const <String, String>{},
  }) {
    final bytes = image.bytes;
    if (bytes == null) {
      throw const Failure(
        code: FailureCode.mediaInvalid,
        message: 'Byte gambar tidak tersedia untuk diunggah.',
        kind: FailureKind.validation,
      );
    }
    return storage.upload(
      FileUpload(
        path: '$directory/${image.name}',
        bytes: bytes,
        contentType: image.mimeType,
        metadata: metadata,
      ),
      onProgress: onProgress,
    );
  }
}
