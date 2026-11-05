import 'package:kiln_core/kiln_core.dart';

import 'device_share_service.dart';
import 'sdk_share_gateway.dart';
import 'share_gateway.dart';
import 'share_support.dart';

/// Registers the native share sheet.
final class ShareModule extends KilnModule {
  const ShareModule();

  @override
  String get id => 'share';

  @override
  Set<String> get provides => const <String>{'share'};

  @override
  Set<String> get platforms => const <String>{
    'android',
    'ios',
    'macos',
    'web',
    'windows',
  };

  @override
  void register(Registry registry) {
    const gateway = SdkShareGateway();
    registry
      ..registerSingleton<ShareGateway>(gateway)
      ..registerSingleton<ShareService>(DeviceShareService(gateway: gateway))
      ..registerSingleton<ShareSupport>(const ShareSupport());
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<ShareSupport>().info;
  }
}
