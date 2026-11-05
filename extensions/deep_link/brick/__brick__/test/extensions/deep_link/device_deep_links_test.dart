import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_config.dart';

import 'test_support.dart';

void main() {
  test('forwards gateway links to listeners', () async {
    final gateway = FakeAppLinksGateway();
    final links = createDeviceDeepLinks(gateway: gateway);
    await links.start();
    final received = <Uri>[];
    final subscription = links.links.listen(received.add);

    gateway.emit(Uri.parse('https://kiln.dev/profile/42'));

    expect(received, [Uri.parse('https://kiln.dev/profile/42')]);

    await subscription.cancel();
    await links.dispose();
  });

  test('captures the initial link after start', () async {
    final gateway = FakeAppLinksGateway(
      link: Uri.parse('kiln://Profile/42/'),
    );
    final links = createDeviceDeepLinks(gateway: gateway);

    expect(links.initialLink, isNull);

    await links.start();

    expect(links.initialLink, Uri.parse('kiln://profile/42'));
    await links.dispose();
  });

  test('keeps the initial link off the stream', () async {
    final gateway = FakeAppLinksGateway(link: Uri.parse('kiln://profile/42'));
    final links = createDeviceDeepLinks(gateway: gateway);
    final received = <Uri>[];
    final subscription = links.links.listen(received.add);

    await links.start();
    await pumpEventQueue();

    expect(links.initialLink, Uri.parse('kiln://profile/42'));
    expect(received, isEmpty);

    await subscription.cancel();
    await links.dispose();
  });

  test('drops links outside the allowlist', () async {
    final gateway = FakeAppLinksGateway();
    final links = createDeviceDeepLinks(gateway: gateway);
    await links.start();
    final received = <Uri>[];
    final subscription = links.links.listen(received.add);

    gateway
      ..emit(Uri.parse('https://evil.example/profile/42'))
      ..emit(Uri.parse('otherapp://profile/42'))
      ..emit(Uri.parse('https://kiln.dev/profile/42'));

    expect(received, [Uri.parse('https://kiln.dev/profile/42')]);

    await subscription.cancel();
    await links.dispose();
  });

  test('enforces the configured path prefixes', () async {
    final gateway = FakeAppLinksGateway();
    final links = createDeviceDeepLinks(
      gateway: gateway,
      config: const DeepLinkConfig(
        scheme: 'kiln',
        allowedHosts: <String>['kiln.dev'],
        pathPrefixes: <String>['/app'],
      ),
    );
    await links.start();
    final received = <Uri>[];
    final subscription = links.links.listen(received.add);

    gateway
      ..emit(Uri.parse('https://kiln.dev/web/1'))
      ..emit(Uri.parse('https://kiln.dev/application'))
      ..emit(Uri.parse('https://kiln.dev/app/1'));

    expect(received, [Uri.parse('https://kiln.dev/app/1')]);

    await subscription.cancel();
    await links.dispose();
  });

  test('replays links that arrive before the first listener once', () async {
    final gateway = FakeAppLinksGateway();
    final links = createDeviceDeepLinks(gateway: gateway);
    await links.start();

    gateway
      ..emit(Uri.parse('https://kiln.dev/profile/1'))
      ..emit(Uri.parse('https://kiln.dev/profile/2'));

    final received = <Uri>[];
    final subscription = links.links.listen(received.add);
    await pumpEventQueue();

    expect(received, <Uri>[
      Uri.parse('https://kiln.dev/profile/1'),
      Uri.parse('https://kiln.dev/profile/2'),
    ]);

    final late = <Uri>[];
    final lateSubscription = links.links.listen(late.add);
    await pumpEventQueue();

    expect(late, isEmpty);

    await subscription.cancel();
    await lateSubscription.cancel();
    await links.dispose();
  });

  test('deduplicates the same link inside the clock window', () async {
    final clock = FixedClock.at(2026, 11, 2, 9);
    final gateway = FakeAppLinksGateway();
    final links = createDeviceDeepLinks(gateway: gateway, clock: clock);
    await links.start();
    final received = <Uri>[];
    final link = Uri.parse('https://kiln.dev/profile/42');
    final subscription = links.links.listen(received.add);

    gateway
      ..emit(link)
      ..emit(link);
    expect(received, [link]);

    clock.advance(const Duration(seconds: 3));
    gateway.emit(link);
    expect(received, [link, link]);

    await subscription.cancel();
    await links.dispose();
  });

  test('records gateway errors as deep link failures', () async {
    final gateway = FakeAppLinksGateway()
      ..initialFailure = PlatformException(code: 'unavailable');
    final links = createDeviceDeepLinks(gateway: gateway);

    await links.start();

    expect(links.lastFailure?.code, FailureCode.deepLinkUnavailable);
    expect(links.lastFailure?.kind, FailureKind.deepLink);

    gateway.emitError(PlatformException(code: 'listen_failed'));

    expect(links.lastFailure?.code, FailureCode.deepLinkUnavailable);
    await links.dispose();
  });

  test('start runs once and dispose releases the gateway', () async {
    final gateway = FakeAppLinksGateway();
    final links = createDeviceDeepLinks(gateway: gateway);

    await links.start();
    await links.start();
    expect(gateway.initialCalls, 1);

    var done = false;
    final subscription = links.links.listen((_) {}, onDone: () => done = true);
    await links.dispose();

    expect(gateway.disposed, isTrue);
    expect(done, isTrue);
    await subscription.cancel();
  });
}
