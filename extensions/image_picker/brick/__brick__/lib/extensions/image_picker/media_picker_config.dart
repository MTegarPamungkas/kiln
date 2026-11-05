/// Image picking settings from the install prompts.
final class MediaPickerConfig {
  const MediaPickerConfig({
    this.maxWidth = 1600,
    this.maxHeight = 1600,
    this.imageQuality = 85,
    this.maxBytes = 5242880,
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

  final int maxWidth;
  final int maxHeight;
  final int imageQuality;
  final int maxBytes;
  final Set<String> allowedTypes;
}
