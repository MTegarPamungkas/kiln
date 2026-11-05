import 'package:image_picker/image_picker.dart';
import 'package:kiln_core/kiln_core.dart';

import 'image_picker_gateway.dart';
import 'media_failure_mapper.dart';

typedef PickedImageConverter = Future<PickedImage> Function(XFile file);

/// Recovers a pick that Android lost when the activity was destroyed.
final class LostDataRecovery {
  const LostDataRecovery({required this.gateway, required this.convert});

  final ImagePickerGateway gateway;
  final PickedImageConverter convert;

  Future<PickedImage?> recover() async {
    try {
      final response = await gateway.retrieveLostData();
      if (response.isEmpty) {
        return null;
      }
      final exception = response.exception;
      if (exception != null) {
        throw exception;
      }
      final file = response.file;
      if (file == null) {
        return null;
      }
      return await convert(file);
    } on Object catch (error, stackTrace) {
      throw mapMediaError(error, stackTrace: stackTrace);
    }
  }
}
