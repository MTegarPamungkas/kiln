/// Where a media picker may read from.
enum MediaSource { camera, gallery }

/// One image chosen by the user.
final class PickedImage {
  const PickedImage({
    required this.path,
    required this.name,
    this.bytes,
    this.mimeType,
    this.width,
    this.height,
    this.sizeBytes,
  });

  final String path;
  final String name;
  final List<int>? bytes;
  final String? mimeType;
  final int? width;
  final int? height;
  final int? sizeBytes;
}

/// Picks images from the camera or the gallery.
abstract interface class MediaPicker {
  Future<PickedImage?> pickImage({
    MediaSource source = MediaSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  });
}
