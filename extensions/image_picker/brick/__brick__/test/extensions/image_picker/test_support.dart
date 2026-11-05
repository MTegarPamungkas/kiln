import 'package:image_picker/image_picker.dart';
import 'package:{{app_name}}/extensions/image_picker/image_picker_gateway.dart';

const List<int> jpegSignature = <int>[0xFF, 0xD8, 0xFF];

const List<int> pngSignature = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
];

const List<int> tinyPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82,
];

final class FakeImagePickerGateway implements ImagePickerGateway {
  XFile? file;
  Object? failure;
  LostDataResponse lost = LostDataResponse.empty();
  final List<ImageSource> sources = <ImageSource>[];
  double? lastMaxWidth;
  double? lastMaxHeight;
  int? lastImageQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    sources.add(source);
    lastMaxWidth = maxWidth;
    lastMaxHeight = maxHeight;
    lastImageQuality = imageQuality;
    final error = failure;
    if (error != null) {
      throw error;
    }
    return file;
  }

  @override
  Future<LostDataResponse> retrieveLostData() async {
    final error = failure;
    if (error != null) {
      throw error;
    }
    return lost;
  }
}
