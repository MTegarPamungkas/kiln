import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/image_picker/media_picker_config.dart';

void main() {
  test('defaults carry the rendered prompts', () {
    const config = MediaPickerConfig.defaults;

    expect(config.maxBytes, 5242880);
    expect(config.allowedTypes, containsAll(<String>[
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'image/gif',
    ]));
    expect(config.maxWidth, 1600);
    expect(config.maxHeight, 1600);
    expect(config.imageQuality, 85);
  });
}
