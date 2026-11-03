import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/image_picker/device_media_picker.dart';
import 'package:{{app_name}}/extensions/image_picker/media_picker_support.dart';

import 'test_support.dart';

void main() {
  test('gallery is supported on every platform', () {
    for (final platform in TargetPlatform.values) {
      final support = MediaPickerSupport(platform: platform);
      expect(
        support.forSource(MediaSource.gallery).isSupported,
        isTrue,
        reason: platform.name,
      );
      expect(support.overall.isSupported, isTrue);
    }
  });

  test('camera support follows the platform', () {
    expect(
      MediaPickerSupport(platform: TargetPlatform.android)
          .forSource(MediaSource.camera)
          .isSupported,
      isTrue,
    );
    expect(
      MediaPickerSupport(platform: TargetPlatform.windows)
          .forSource(MediaSource.camera)
          .state,
      SupportState.unsupportedDevice,
    );
    expect(
      MediaPickerSupport(platform: TargetPlatform.linux)
          .forSource(MediaSource.camera)
          .state,
      SupportState.unsupportedDevice,
    );
    expect(
      MediaPickerSupport(
        platform: TargetPlatform.linux,
        isWeb: true,
      ).forSource(MediaSource.camera).isSupported,
      isTrue,
    );
    expect(
      MediaPickerSupport(platform: TargetPlatform.fuchsia)
          .forSource(MediaSource.camera)
          .state,
      SupportState.unsupportedPlatform,
    );
  });

  test('unsupported camera returns info without calling the plugin', () async {
    final gateway = FakeImagePickerGateway();
    final picker = DeviceMediaPicker(
      gateway: gateway,
      support: const MediaPickerSupport(platform: TargetPlatform.linux),
    );

    await expectLater(
      picker.pickImage(source: MediaSource.camera),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.unsupportedDevice,
        ),
      ),
    );
    expect(gateway.sources, isEmpty);
  });
}
