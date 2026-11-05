import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/image_picker/device_media_picker.dart';
import 'package:{{app_name}}/extensions/image_picker/media_picker_config.dart';

import 'test_support.dart';

void main() {
  mediaPickerContract(
    description: 'DeviceMediaPicker',
    create: ({result, cancelled, failure}) {
      final gateway = FakeImagePickerGateway();
      if (failure != null) {
        gateway.failure = failure;
      } else if (result != null && cancelled != true) {
        gateway.file = XFile.fromData(
          Uint8List.fromList(jpegSignature),
          path: result.path,
          mimeType: result.mimeType,
        );
      }
      return DeviceMediaPicker(
        gateway: gateway,
        config: const MediaPickerConfig(),
      );
    },
  );
}
