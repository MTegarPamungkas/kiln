import 'package:kiln_core/kiln_core.dart';

import 'camera_permission_precheck.dart';
import 'device_media_picker.dart';
import 'image_picker_gateway.dart';
import 'lost_data_recovery.dart';
import 'media_picker_config.dart';
import 'picked_image_upload_adapter.dart';

/// Registers MediaPicker and the optional upload adapter.
final class ImagePickerModule extends KilnModule {
  const ImagePickerModule();

  @override
  String get id => 'image_picker';

  @override
  Set<String> get provides => const <String>{'media'};

  @override
  Set<String> get optionalRequires => const <String>{
    'permission',
    'file_storage',
  };

  @override
  void register(Registry registry) {
    const config = MediaPickerConfig.defaults;
    final gateway = SdkImagePickerGateway();
    final picker = DeviceMediaPicker(
      gateway: gateway,
      config: config,
      permissionPrecheck: CameraPermissionPrecheck(
        permissions: registry.readOrNull<Permissions>(),
      ),
    );
    final recovery = LostDataRecovery(
      gateway: gateway,
      convert: picker.fromFile,
    );

    registry
      ..registerSingleton<MediaPickerConfig>(config)
      ..registerSingleton<MediaPicker>(picker)
      ..registerSingleton<LostDataRecovery>(recovery);

    final storage = registry.readOrNull<FileStorage>();
    if (storage != null) {
      registry.registerSingleton<PickedImageUploadAdapter>(
        PickedImageUploadAdapter(storage: storage),
      );
    }
  }
}
