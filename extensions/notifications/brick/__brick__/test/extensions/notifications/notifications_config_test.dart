import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/notifications/notifications_config.dart';

void main() {
  test('defaults carry the rendered prompts', () {
    const config = NotificationsConfig.defaults;

    expect(config.defaultChannelId, '{{{default_channel}}}');
    expect(config.smallIcon, '{{{small_icon}}}');
    expect(config.exactAlarms, {{{exact_alarms}}});
  });
}
