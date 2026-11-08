import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/deep_link/app_link_builder.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_config.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_module.dart';
import 'package:{{app_name}}/extensions/deep_link/device_deep_links.dart';

void main() {
  test('module registers DeepLinks, its config, and the builder', () {
    final registry = GetItRegistry();

    const DeepLinkModule().register(registry);

    expect(registry.read<DeepLinks>(), isA<DeviceDeepLinks>());
    expect(registry.read<DeepLinkConfig>().scheme, '{{scheme}}');
    expect(registry.read<AppLinkBuilder>(), isA<AppLinkBuilder>());
  });

  test('module uses the registered clock', () {
    final clock = FixedClock.at(2026, 11, 2, 9);
    final registry = GetItRegistry()..registerSingleton<Clock>(clock);

    const DeepLinkModule().register(registry);

    final links = registry.read<DeepLinks>();
    expect(links, isA<DeviceDeepLinks>());
    expect((links as DeviceDeepLinks).clock, same(clock));
  });
}
