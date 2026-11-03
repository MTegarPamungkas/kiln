import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('connectivity brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'net_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/connectivity/connectivity_module.dart',
        'lib/extensions/connectivity/device_network_monitor.dart',
        'lib/extensions/connectivity/offline_guard_middleware.dart',
        'lib/extensions/connectivity/widgets/offline_banner.dart',
        'lib/extensions/connectivity/widgets/network_status_builder.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('connectivity_config.dart'),
    );
    expect(
      String.fromCharCodes(config.bytes),
      contains('debounceWindow: Duration(milliseconds: 500)'),
    );
  });
}
