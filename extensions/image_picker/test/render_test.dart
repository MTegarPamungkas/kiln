import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('image_picker brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'media_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/image_picker/image_picker_module.dart',
        'lib/extensions/image_picker/device_media_picker.dart',
        'lib/extensions/image_picker/image_picker_gateway.dart',
        'lib/extensions/image_picker/media_picker_config.dart',
        'lib/extensions/image_picker/media_failure_mapper.dart',
        'lib/extensions/image_picker/mime_sniffer.dart',
        'lib/extensions/image_picker/image_validator.dart',
        'lib/extensions/image_picker/camera_permission_precheck.dart',
        'lib/extensions/image_picker/lost_data_recovery.dart',
        'lib/extensions/image_picker/picked_image_x.dart',
        'lib/extensions/image_picker/picked_image_upload_adapter.dart',
        'lib/extensions/image_picker/widgets/image_source_sheet.dart',
        'lib/extensions/image_picker/widgets/avatar_picker.dart',
        'test/extensions/image_picker/media_picker_contract_test.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('media_picker_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains('maxBytes: 5242880'));
    expect(source, contains("'image/jpeg'"));
  });
}
