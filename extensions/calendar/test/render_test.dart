import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('calendar brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'cal_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/calendar/calendar_module.dart',
        'lib/extensions/calendar/calendar_support.dart',
        'lib/extensions/calendar/calendar_gateway.dart',
        'lib/extensions/calendar/add_2_calendar_gateway.dart',
        'lib/extensions/calendar/device_calendar_service.dart',
        'test/extensions/calendar/calendar_test.dart',
      ]),
    );
  });
}
