import 'package:kiln_core/kiln_core.dart';

import 'app_link_builder.dart';
import 'app_links_gateway.dart';
import 'deep_link_config.dart';
import 'device_deep_links.dart';

/// Registers DeepLinks, its config, and the outgoing link builder.
final class DeepLinkModule extends KilnModule {
  const DeepLinkModule();

  @override
  String get id => 'deep_link';

  @override
  Set<String> get provides => const <String>{'deep_links'};

  @override
  void register(Registry registry) {
    const config = DeepLinkConfig.defaults;
    final links = DeviceDeepLinks(
      gateway: SdkAppLinksGateway(),
      config: config,
      clock: registry.readOrNull<Clock>(),
    );

    registry
      ..registerSingleton<DeepLinkConfig>(config)
      ..registerSingleton<AppLinkBuilder>(AppLinkBuilder(config: config))
      ..registerSingleton<DeepLinks>(links);
  }

  @override
  Future<SupportInfo> support(Registry registry) async {
    final links = registry.read<DeepLinks>();
    if (links is DeviceDeepLinks) {
      return links.probeSupport();
    }
    return const SupportInfo.supported();
  }

  @override
  Future<void> ready(Registry registry) async {
    final links = registry.read<DeepLinks>();
    if (links is! DeviceDeepLinks) {
      return;
    }
    try {
      await links.start();
    } on Object catch (error) {
      registry.read<SupportRegistry>().record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Deep links could not start: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }
}
