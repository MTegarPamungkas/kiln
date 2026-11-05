import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_auth_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_auth_repository.dart';
import 'package:{{app_name}}/extensions/neon/neon_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_file_storage.dart';
import 'package:{{app_name}}/extensions/neon/neon_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_module.dart';
import 'package:{{app_name}}/extensions/neon/neon_query_mapper.dart';
import 'package:{{app_name}}/extensions/neon/neon_remote_database.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_storage_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_support.dart';

import 'test_support.dart';

void main() {
  test('module declares the neon capabilities', () {
    final module = NeonModule();

    expect(module.id, 'neon');
    expect(
      module.provides,
      containsAll(<String>['auth', 'remote_database', 'file_storage']),
    );
  });

  test('module registers the auth, database, and storage wiring', () {
    final registry = GetItRegistry();
    NeonModule(
      config: testConfig(),
      storageConfig: testStorageConfig(),
      gatewayFactory: (_, __) => FakePostgrestGateway(),
      storageGatewayFactory: (_) => FakeNeonStorageGateway(),
      authGatewayFactory: (_) => FakeNeonAuthGateway(),
    ).register(registry);

    expect(registry.read<NeonConfig>(), isA<NeonConfig>());
    expect(registry.read<NeonStorageConfig>(), isA<NeonStorageConfig>());
    expect(registry.read<NeonSupport>(), isA<NeonSupport>());
    expect(registry.read<NeonQueryMapper>(), isA<NeonQueryMapper>());
    expect(registry.read<PostgrestGateway>(), isA<FakePostgrestGateway>());
    expect(
      registry.read<NeonStorageGateway>(),
      isA<FakeNeonStorageGateway>(),
    );
    expect(registry.read<NeonAuthGateway>(), isA<FakeNeonAuthGateway>());
    expect(registry.read<AuthRepository>(), isA<NeonAuthRepository>());
    expect(registry.read<SessionController>(), isA<SessionController>());
    expect(registry.read<RemoteDatabase>(), isA<NeonRemoteDatabase>());
    expect(registry.read<FileStorage>(), isA<NeonFileStorage>());
  });

  test('the default module builds HTTP-backed gateways', () {
    final registry = GetItRegistry();
    NeonModule(config: testConfig(), storageConfig: testStorageConfig())
        .register(registry);

    expect(registry.read<PostgrestGateway>(), isA<HttpNeonGateway>());
    expect(registry.read<NeonStorageGateway>(), isA<S3NeonStorageGateway>());
    expect(registry.read<NeonAuthGateway>(), isA<BetterAuthGateway>());
  });

  test('support reports database and storage configured', () async {
    final registry = GetItRegistry();
    final module = NeonModule(
      config: testConfig(),
      storageConfig: testStorageConfig(),
    );
    module.register(registry);

    final info = await module.support(registry);

    expect(info.isSupported, isTrue);
    expect(info.details['storage_configured'], isTrue);
    expect(info.details['storage_bucket'], 'files');
  });
}
