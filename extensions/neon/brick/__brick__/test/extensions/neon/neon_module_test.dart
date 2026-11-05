import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_module.dart';
import 'package:{{app_name}}/extensions/neon/neon_query_mapper.dart';
import 'package:{{app_name}}/extensions/neon/neon_remote_database.dart';
import 'package:{{app_name}}/extensions/neon/neon_support.dart';

import 'test_support.dart';

void main() {
  test('module declares the neon capability', () {
    final module = NeonModule();

    expect(module.id, 'neon');
    expect(module.provides, contains('remote_database'));
  });

  test('module registers the config, gateway, and database', () {
    final registry = GetItRegistry();
    NeonModule(config: testConfig(), gatewayFactory: (_) => FakePostgrestGateway())
        .register(registry);

    expect(registry.read<NeonConfig>(), isA<NeonConfig>());
    expect(registry.read<NeonSupport>(), isA<NeonSupport>());
    expect(registry.read<NeonQueryMapper>(), isA<NeonQueryMapper>());
    expect(registry.read<PostgrestGateway>(), isA<FakePostgrestGateway>());
    expect(registry.read<RemoteDatabase>(), isA<NeonRemoteDatabase>());
  });

  test('the default module builds an HTTP gateway', () {
    final registry = GetItRegistry();
    NeonModule(config: testConfig()).register(registry);

    expect(registry.read<PostgrestGateway>(), isA<HttpNeonGateway>());
  });

  test('support reads through the registered NeonSupport', () async {
    final registry = GetItRegistry();
    final module = NeonModule(config: testConfig());
    module.register(registry);

    final info = await module.support(registry);

    expect(info.isSupported, isTrue);
  });
}
