import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/image_picker/device_media_picker.dart';
import 'package:{{app_name}}/extensions/image_picker/lost_data_recovery.dart';

import 'test_support.dart';

XFile _jpegFile() {
  return XFile.fromData(
    Uint8List.fromList(jpegSignature),
    path: '/tmp/lost.jpg',
    mimeType: 'image/jpeg',
  );
}

void main() {
  test('recovers the image lost when the activity was destroyed', () async {
    final gateway = FakeImagePickerGateway()
      ..lost = LostDataResponse(
        file: _jpegFile(),
        type: RetrieveType.image,
      );
    final picker = DeviceMediaPicker(gateway: gateway);
    final recovery = LostDataRecovery(
      gateway: gateway,
      convert: picker.fromFile,
    );

    final recovered = await recovery.recover();

    expect(recovered, isNotNull);
    expect(recovered!.path, '/tmp/lost.jpg');
    expect(recovered.mimeType, 'image/jpeg');
  });

  test('returns null when nothing was lost', () async {
    final gateway = FakeImagePickerGateway();
    final picker = DeviceMediaPicker(gateway: gateway);
    final recovery = LostDataRecovery(
      gateway: gateway,
      convert: picker.fromFile,
    );

    expect(await recovery.recover(), isNull);
  });

  test('returns null when the response has no file', () async {
    final gateway = FakeImagePickerGateway()
      ..lost = LostDataResponse(type: RetrieveType.image);
    final picker = DeviceMediaPicker(gateway: gateway);
    final recovery = LostDataRecovery(
      gateway: gateway,
      convert: picker.fromFile,
    );

    expect(await recovery.recover(), isNull);
  });

  test('maps the stored exception', () async {
    final gateway = FakeImagePickerGateway()
      ..lost = LostDataResponse(
        exception: PlatformException(code: 'camera_access_denied'),
        type: RetrieveType.image,
      );
    final picker = DeviceMediaPicker(gateway: gateway);
    final recovery = LostDataRecovery(
      gateway: gateway,
      convert: picker.fromFile,
    );

    await expectLater(
      recovery.recover(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.mediaPermissionDenied,
        ),
      ),
    );
  });
}
