import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('reports supported and captures the launch link once', () async {
    final gateway = FakeAppLinksGateway(link: Uri.parse('kiln://profile/42'));
    final links = createDeviceDeepLinks(gateway: gateway);

    final info = await links.probeSupport();

    expect(info.isSupported, isTrue);
    expect(links.initialLink, Uri.parse('kiln://profile/42'));

    await links.start();
    expect(gateway.initialCalls, 1);

    await links.dispose();
  });

  test('maps a missing plugin to unsupported platform', () async {
    final gateway = FakeAppLinksGateway()
      ..initialFailure = MissingPluginException('no app links');
    final links = createDeviceDeepLinks(gateway: gateway);

    final info = await links.probeSupport();

    expect(info.state, SupportState.unsupportedPlatform);
    expect(info.toFailure().code, FailureCode.unsupportedPlatform);
    expect(links.lastFailure, isNotNull);

    await links.dispose();
  });

  test('maps other failures to unavailable', () async {
    final gateway = FakeAppLinksGateway()
      ..initialFailure = StateError('platform failed');
    final links = createDeviceDeepLinks(gateway: gateway);

    final info = await links.probeSupport();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);

    await links.dispose();
  });

  test('caches the support result', () async {
    final gateway = FakeAppLinksGateway();
    final links = createDeviceDeepLinks(gateway: gateway);

    await links.probeSupport();
    await links.probeSupport();

    expect(gateway.initialCalls, 1);
    await links.dispose();
  });
}
