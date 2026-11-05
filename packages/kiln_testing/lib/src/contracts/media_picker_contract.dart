import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef MediaPickerContractFactory = MediaPicker Function({
  PickedImage? result,
  bool? cancelled,
  Failure? failure,
});

/// Behavior every [MediaPicker] implementation must share.
void mediaPickerContract({
  required MediaPickerContractFactory create,
  String description = 'MediaPicker',
}) {
  group('$description contract', () {
    test('returns the picked image', () async {
      const image = PickedImage(
        path: '/tmp/photo.jpg',
        name: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 3,
      );
      final picker = create(result: image);

      final picked = await picker.pickImage();

      expect(picked, isNotNull);
      expect(picked!.path, image.path);
      expect(picked.name, image.name);
      expect(picked.mimeType, image.mimeType);
      expect(picked.sizeBytes, image.sizeBytes);
    });

    test('returns null when the user cancels', () async {
      final picker = create(cancelled: true);

      expect(await picker.pickImage(), isNull);
    });

    test('throws a Failure when the picker fails', () async {
      const failure = Failure(
        code: FailureCode.mediaUnavailable,
        message: 'Camera unavailable',
        kind: FailureKind.media,
      );
      final picker = create(failure: failure);

      await expectLater(
        picker.pickImage(source: MediaSource.camera),
        throwsA(
          isA<Failure>().having(
            (value) => value.code,
            'code',
            FailureCode.mediaUnavailable,
          ),
        ),
      );
    });
  });
}
