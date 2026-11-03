import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('notifications brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'notif_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/notifications/notifications_module.dart',
        'lib/extensions/notifications/device_notifications.dart',
        'lib/extensions/notifications/notification_gateway.dart',
        'lib/extensions/notifications/plugin_notification_gateway.dart',
        'lib/extensions/notifications/notification_channels.dart',
        'lib/extensions/notifications/timezone_resolver.dart',
        'lib/extensions/notifications/notification_payload.dart',
        'lib/extensions/notifications/notification_id_allocator.dart',
        'lib/extensions/notifications/notification_tap_hub.dart',
        'lib/extensions/notifications/background_tap_handler.dart',
        'lib/extensions/notifications/notification_permission_flow.dart',
        'lib/extensions/notifications/reminder_scheduler.dart',
        'test/extensions/notifications/notifications_contract_test.dart',
      ]),
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('notifications_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains("defaultChannelId: 'kiln_default'"));
    expect(source, contains('exactAlarms: false'));
  });
}
