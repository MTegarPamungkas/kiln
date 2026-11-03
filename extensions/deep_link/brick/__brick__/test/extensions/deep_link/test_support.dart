import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_config.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_gateway.dart';
import 'package:{{app_name}}/extensions/deep_link/device_deep_links.dart';

/// [DeepLinkConfig] used by most tests.
const DeepLinkConfig testConfig = DeepLinkConfig(
  scheme: 'kiln',
  allowedHosts: <String>['kiln.dev'],
);

/// [AppLinksGateway] whose links and errors are emitted by the test.
final class FakeAppLinksGateway implements AppLinksGateway {
  FakeAppLinksGateway({this.link});

  Uri? link;
  Object? initialFailure;
  bool disposed = false;
  int initialCalls = 0;

  final StreamController<Uri> _links = StreamController<Uri>.broadcast(
    sync: true,
  );

  @override
  Future<Uri?> initialLink() async {
    initialCalls += 1;
    final error = initialFailure;
    if (error != null) {
      throw error;
    }
    return link;
  }

  @override
  Stream<Uri> get links => _links.stream;

  void emit(Uri link) {
    if (!_links.isClosed) {
      _links.add(link);
    }
  }

  void emitError(Object error) {
    if (!_links.isClosed) {
      _links.addError(error);
    }
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _links.close();
  }
}

DeviceDeepLinks createDeviceDeepLinks({
  required FakeAppLinksGateway gateway,
  DeepLinkConfig config = testConfig,
  Clock? clock,
}) {
  return DeviceDeepLinks(gateway: gateway, config: config, clock: clock);
}
