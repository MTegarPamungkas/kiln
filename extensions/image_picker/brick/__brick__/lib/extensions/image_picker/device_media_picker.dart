import 'package:image_picker/image_picker.dart' as ip;
import 'package:kiln_core/kiln_core.dart';

import 'camera_permission_precheck.dart';
import 'image_picker_gateway.dart';
import 'image_validator.dart';
import 'media_failure_mapper.dart';
import 'media_picker_config.dart';
import 'media_picker_support.dart';
import 'mime_sniffer.dart';

/// [MediaPicker] on top of an ImagePickerGateway.
final class DeviceMediaPicker implements MediaPicker {
  DeviceMediaPicker({
    required this.gateway,
    this.config = MediaPickerConfig.defaults,
    ImageValidator? validator,
    this.permissionPrecheck,
    MediaPickerSupport? support,
  }) : validator = validator ?? ImageValidator(config: config),
       support = support ?? MediaPickerSupport.current();

  final ImagePickerGateway gateway;
  final ImageValidator validator;
  final CameraPermissionPrecheck? permissionPrecheck;
  final MediaPickerSupport support;
  final MediaPickerConfig config;

  @override
  Future<PickedImage?> pickImage({
    MediaSource source = MediaSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    final supportInfo = support.forSource(source);
    if (!supportInfo.isSupported) {
      throw supportInfo.toFailure();
    }
    try {
      await permissionPrecheck?.ensure(source);
      final file = await gateway.pickImage(
        source: switch (source) {
          MediaSource.camera => ip.ImageSource.camera,
          MediaSource.gallery => ip.ImageSource.gallery,
        },
        maxWidth: (maxWidth ?? config.maxWidth).toDouble(),
        maxHeight: (maxHeight ?? config.maxHeight).toDouble(),
        imageQuality: imageQuality ?? config.imageQuality,
      );
      if (file == null) {
        return null;
      }
      return await fromFile(file);
    } on Object catch (error, stackTrace) {
      throw mapMediaError(error, stackTrace: stackTrace);
    }
  }

  /// Converts a picked file, detecting the type from its bytes.
  Future<PickedImage> fromFile(ip.XFile file) async {
    final bytes = await file.readAsBytes();
    final mime = MimeSniffer.detect(bytes) ?? file.mimeType;
    final image = PickedImage(
      path: file.path,
      name: _nameOf(file),
      bytes: bytes,
      mimeType: mime,
      sizeBytes: bytes.length,
    );
    final normalized = validator.ensureValid(image);
    if (normalized == mime) {
      return image;
    }
    return PickedImage(
      path: image.path,
      name: image.name,
      bytes: image.bytes,
      mimeType: normalized,
      sizeBytes: image.sizeBytes,
    );
  }

  String _nameOf(ip.XFile file) {
    final name = file.name;
    final slash = name.lastIndexOf('/');
    final backslash = name.lastIndexOf('\\');
    final index = slash > backslash ? slash : backslash;
    return index == -1 ? name : name.substring(index + 1);
  }
}
