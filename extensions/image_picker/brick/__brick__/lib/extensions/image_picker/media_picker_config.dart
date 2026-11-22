/// Image picking settings from the install prompts.
final class MediaPickerConfig {
  const MediaPickerConfig({
    this.maxWidth = 1600,
    this.maxHeight = 1600,
    this.imageQuality = 85,
    this.maxBytes = 5242880,
    this.maxDecodedWidth = 20000,
    this.maxDecodedHeight = 20000,
    this.maxDecodedPixels = 50000000,
    this.allowedTypes = const <String>{
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'image/gif',
    },
  });

  static const defaults = MediaPickerConfig(
    maxBytes: {{max_bytes}},
    allowedTypes: <String>{
      {{#allowed_types}}'{{{.}}}',
      {{/allowed_types}}
    },
  );

  /// Target width passed to the picker for downscaling. Not a reject limit.
  final int maxWidth;

  /// Target height passed to the picker for downscaling. Not a reject limit.
  final int maxHeight;

  final int imageQuality;
  final int maxBytes;

  /// Largest intrinsic width accepted from the encoded header.
  final int maxDecodedWidth;

  /// Largest intrinsic height accepted from the encoded header.
  final int maxDecodedHeight;

  /// Largest intrinsic pixel count (`width * height`) accepted.
  ///
  /// A header that declares more than this would allocate a large bitmap when
  /// decoded, so the image is rejected before it reaches the decoder.
  final int maxDecodedPixels;

  final Set<String> allowedTypes;
}
