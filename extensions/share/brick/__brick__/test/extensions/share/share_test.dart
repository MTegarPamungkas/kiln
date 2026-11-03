import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/share/device_share_service.dart';
import 'package:{{app_name}}/extensions/share/share_gateway.dart';
import 'package:{{app_name}}/extensions/share/share_module.dart';
import 'package:{{app_name}}/extensions/share/share_support.dart';

final class _FakeGateway implements ShareGateway {
  ShareOutcome result = ShareOutcome.shared;
  ShareContent? lastContent;
  ShareOrigin? lastOrigin;

  @override
  Future<ShareOutcome> share(
    ShareContent content, {
    ShareOrigin? origin,
  }) async {
    lastContent = content;
    lastOrigin = origin;
    return result;
  }
}

void main() {
  test('delegates content and origin to the gateway', () async {
    final gateway = _FakeGateway();
    final service = DeviceShareService(gateway: gateway);
    const content = ShareContent(text: 'Bali Weekend', subject: 'Trip');
    const origin = ShareOrigin(left: 1, top: 2, width: 3, height: 4);

    final result = await service.share(content, origin: origin);

    expect(result, ShareOutcome.shared);
    expect(gateway.lastContent, same(content));
    expect(gateway.lastOrigin, same(origin));
  });

  test('module registers the share service and support', () {
    final registry = GetItRegistry();

    const ShareModule().register(registry);

    expect(registry.read<ShareService>(), isA<ShareService>());
    expect(registry.read<ShareGateway>(), isA<ShareGateway>());
    expect(registry.read<ShareSupport>(), isA<ShareSupport>());
  });

  test('reports supported', () {
    expect(const ShareSupport().info.isSupported, isTrue);
  });
}
