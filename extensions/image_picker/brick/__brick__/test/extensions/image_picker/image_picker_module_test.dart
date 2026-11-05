import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/image_picker/device_media_picker.dart';
import 'package:{{app_name}}/extensions/image_picker/image_picker_module.dart';
import 'package:{{app_name}}/extensions/image_picker/lost_data_recovery.dart';
import 'package:{{app_name}}/extensions/image_picker/media_picker_config.dart';
import 'package:{{app_name}}/extensions/image_picker/picked_image_upload_adapter.dart';

void main() {
  test('module registers MediaPicker, config, and recovery', () {
    final registry = GetItRegistry();

    const ImagePickerModule().register(registry);

    expect(registry.read<MediaPicker>(), isA<DeviceMediaPicker>());
    expect(registry.read<MediaPickerConfig>(), isA<MediaPickerConfig>());
    expect(registry.read<LostDataRecovery>(), isA<LostDataRecovery>());
    expect(registry.readOrNull<PickedImageUploadAdapter>(), isNull);
  });

  test('module adds the upload adapter when FileStorage exists', () {
    final registry = GetItRegistry()
      ..registerSingleton<FileStorage>(FakeFileStorage());

    const ImagePickerModule().register(registry);

    expect(
      registry.read<PickedImageUploadAdapter>(),
      isA<PickedImageUploadAdapter>(),
    );
  });
}
