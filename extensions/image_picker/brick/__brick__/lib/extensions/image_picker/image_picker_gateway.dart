import 'package:image_picker/image_picker.dart';

/// Platform image picking that can be faked in tests.
abstract interface class ImagePickerGateway {
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  });

  Future<LostDataResponse> retrieveLostData();
}

/// Gateway backed by the image_picker plugin.
final class SdkImagePickerGateway implements ImagePickerGateway {
  SdkImagePickerGateway({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  @override
  Future<LostDataResponse> retrieveLostData() => _picker.retrieveLostData();
}
