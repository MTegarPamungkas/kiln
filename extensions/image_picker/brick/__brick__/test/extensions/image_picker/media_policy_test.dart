import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/image_picker/device_media_picker.dart';
import 'package:{{app_name}}/extensions/image_picker/image_validator.dart';
import 'package:{{app_name}}/extensions/image_picker/lost_data_recovery.dart';
import 'package:{{app_name}}/extensions/image_picker/media_picker_config.dart';
import 'package:{{app_name}}/extensions/image_picker/picked_image_upload_adapter.dart';

import 'test_support.dart';

/// One validation policy for recovered and freshly picked images.
///
/// A file recovered after the activity was destroyed enters through the same
/// converter as a normal pick, so a size or dimension limit cannot be enforced
/// on one path and skipped on the other.
void main() {
  DeviceMediaPicker pickerFor(
    FakeImagePickerGateway gateway,
    MediaPickerConfig config,
  ) {
    return DeviceMediaPicker(
      gateway: gateway,
      config: config,
      validator: ImageValidator(config: config),
    );
  }

  XFile lost(List<int> bytes, String path) {
    return XFile.fromData(Uint8List.fromList(bytes), path: path);
  }

  group('recovery applies the same limits as a direct pick', () {
    test('an oversized recovered image is rejected', () async {
      final gateway = FakeImagePickerGateway()
        ..lost = LostDataResponse(
          file: lost(tinyPng, '/tmp/lost.png'),
          type: RetrieveType.image,
        );
      const config = MediaPickerConfig(maxBytes: 8);
      final picker = pickerFor(gateway, config);

      await expectLater(
        LostDataRecovery(gateway: gateway, convert: picker.fromFile).recover(),
        throwsA(
          isA<Failure>()
              .having(
                (failure) => failure.code,
                'code',
                FailureCode.mediaInvalid,
              )
              .having((failure) => failure.kind, 'kind', FailureKind.validation),
        ),
      );
    });

    test('a recovered image over the decode limit is rejected', () async {
      const config = MediaPickerConfig(maxDecodedWidth: 4, maxDecodedHeight: 4);
      final gateway = FakeImagePickerGateway()
        ..lost = LostDataResponse(
          file: lost(pngWithSize(64, 64), '/tmp/lost.png'),
          type: RetrieveType.image,
        );
      final picker = pickerFor(gateway, config);

      await expectLater(
        LostDataRecovery(gateway: gateway, convert: picker.fromFile).recover(),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.mediaInvalid,
          ),
        ),
      );
    });

    test('a valid recovered image uploads with its detected type', () async {
      final gateway = FakeImagePickerGateway()
        ..lost = LostDataResponse(
          file: lost(tinyPng, '/tmp/lost.png'),
          type: RetrieveType.image,
        );
      final picker = pickerFor(gateway, MediaPickerConfig.defaults);
      final recovered = await LostDataRecovery(
        gateway: gateway,
        convert: picker.fromFile,
      ).recover();
      expect(recovered, isNotNull);

      final storage = FakeFileStorage();
      final stored = await PickedImageUploadAdapter(
        storage: storage,
      ).upload(recovered!);

      expect(stored.contentType, 'image/png');
      expect(storage.files['images/lost.png'], isNotNull);
    });
  });

  group('cancellation stays distinct from validation rejection', () {
    test('denied permission maps to mediaPermissionDenied', () async {
      final gateway = FakeImagePickerGateway()
        ..failure = PlatformException(code: 'photo_access_denied');
      final picker = DeviceMediaPicker(gateway: gateway);

      await expectLater(
        picker.pickImage(),
        throwsA(
          isA<Failure>()
              .having(
                (failure) => failure.code,
                'code',
                FailureCode.mediaPermissionDenied,
              )
              .having((failure) => failure.kind, 'kind', FailureKind.permission),
        ),
      );
    });

    test('a cancelled recovery maps to mediaCancelled', () async {
      final gateway = FakeImagePickerGateway()
        ..lost = LostDataResponse(
          exception: PlatformException(code: 'canceled'),
          type: RetrieveType.image,
        );
      final picker = DeviceMediaPicker(gateway: gateway);

      await expectLater(
        LostDataRecovery(gateway: gateway, convert: picker.fromFile).recover(),
        throwsA(
          isA<Failure>()
              .having(
                (failure) => failure.code,
                'code',
                FailureCode.mediaCancelled,
              )
              .having((failure) => failure.kind, 'kind', FailureKind.cancelled),
        ),
      );
    });
  });
}
