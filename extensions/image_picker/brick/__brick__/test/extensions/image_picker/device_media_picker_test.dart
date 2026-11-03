import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/image_picker/camera_permission_precheck.dart';
import 'package:{{app_name}}/extensions/image_picker/device_media_picker.dart';
import 'package:{{app_name}}/extensions/image_picker/media_picker_config.dart';

import 'test_support.dart';

XFile _jpegFile({String path = '/tmp/photo.jpg'}) {
  return XFile.fromData(
    Uint8List.fromList(jpegSignature),
    path: path,
    mimeType: 'image/jpeg',
  );
}

void main() {
  test('picks a gallery image with the configured options', () async {
    final gateway = FakeImagePickerGateway()..file = _jpegFile();
    final picker = DeviceMediaPicker(gateway: gateway);

    final picked = await picker.pickImage();

    expect(picked, isNotNull);
    expect(picked!.path, '/tmp/photo.jpg');
    expect(picked.name, 'photo.jpg');
    expect(picked.mimeType, 'image/jpeg');
    expect(picked.sizeBytes, jpegSignature.length);
    expect(gateway.sources, [ImageSource.gallery]);
    expect(gateway.lastMaxWidth, 1600);
    expect(gateway.lastMaxHeight, 1600);
    expect(gateway.lastImageQuality, 85);
  });

  test('opens the camera and checks its permission first', () async {
    final permissions = FakePermissions();
    final gateway = FakeImagePickerGateway()..file = _jpegFile();
    final picker = DeviceMediaPicker(
      gateway: gateway,
      permissionPrecheck: CameraPermissionPrecheck(permissions: permissions),
    );

    await picker.pickImage(source: MediaSource.camera);

    expect(permissions.statusChecks, [PermissionKind.camera]);
    expect(gateway.sources, [ImageSource.camera]);
  });

  test('returns null when the user cancels', () async {
    final picker = DeviceMediaPicker(gateway: FakeImagePickerGateway());

    expect(await picker.pickImage(), isNull);
  });

  test('maps plugin failures', () async {
    final gateway = FakeImagePickerGateway()
      ..failure = PlatformException(code: 'camera_access_denied');
    final picker = DeviceMediaPicker(gateway: gateway);

    await expectLater(
      picker.pickImage(source: MediaSource.camera),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.mediaPermissionDenied,
        ),
      ),
    );
  });

  test('rejects images outside the allowed types', () async {
    final gateway = FakeImagePickerGateway()
      ..file = XFile.fromData(
        Uint8List.fromList(pngSignature),
        path: '/tmp/photo.png',
        mimeType: 'image/png',
      );
    final picker = DeviceMediaPicker(
      gateway: gateway,
      config: const MediaPickerConfig(allowedTypes: <String>{'image/jpeg'}),
    );

    await expectLater(
      picker.pickImage(),
      throwsA(
        isA<Failure>()
            .having((failure) => failure.code, 'code', FailureCode.mediaInvalid)
            .having(
              (failure) => failure.kind,
              'kind',
              FailureKind.validation,
            ),
      ),
    );
  });

  test('detects the type from bytes instead of the plugin mime type', () async {
    final gateway = FakeImagePickerGateway()
      ..file = XFile.fromData(
        Uint8List.fromList(jpegSignature),
        path: '/tmp/photo.bin',
        mimeType: 'application/octet-stream',
      );
    final picker = DeviceMediaPicker(gateway: gateway);

    expect((await picker.pickImage())!.mimeType, 'image/jpeg');
  });
}
