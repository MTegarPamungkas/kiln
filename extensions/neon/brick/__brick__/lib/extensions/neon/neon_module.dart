import 'package:kiln_core/kiln_core.dart';

import 'neon_config.dart';
import 'neon_file_storage.dart';
import 'neon_gateway.dart';
import 'neon_query_mapper.dart';
import 'neon_remote_database.dart';
import 'neon_storage_config.dart';
import 'neon_storage_gateway.dart';
import 'neon_support.dart';

/// Registers [RemoteDatabase] and [FileStorage] over the Neon backend.
///
/// Database access goes through the Data API (PostgREST); files go through
/// Object Storage (S3-compatible). Factories can swap the HTTP gateways for
/// in-memory fakes in tests.
final class NeonModule extends KilnModule {
  NeonModule({
    NeonConfig? config,
    NeonStorageConfig? storageConfig,
    PostgrestGateway Function(NeonConfig config)? gatewayFactory,
    NeonStorageGateway Function(NeonStorageConfig config)? storageGatewayFactory,
  }) : _config = config ?? NeonConfig.defaults,
       _storageConfig = storageConfig ?? NeonStorageConfig.defaults,
       _gatewayFactory = gatewayFactory ??
           ((config) => HttpNeonGateway(config: config)),
       _storageGatewayFactory = storageGatewayFactory ??
           ((config) => S3NeonStorageGateway(config: config));

  final NeonConfig _config;
  final NeonStorageConfig _storageConfig;
  final PostgrestGateway Function(NeonConfig config) _gatewayFactory;
  final NeonStorageGateway Function(NeonStorageConfig config)
  _storageGatewayFactory;
  PostgrestGateway? _gateway;
  NeonStorageGateway? _storageGateway;

  @override
  String get id => 'neon';

  @override
  Set<String> get provides => const <String>{'remote_database', 'file_storage'};

  @override
  void register(Registry registry) {
    final gateway = _gatewayFactory(_config);
    _gateway = gateway;
    final storageGateway = _storageGatewayFactory(_storageConfig);
    _storageGateway = storageGateway;
    final mapper = const NeonQueryMapper();
    final database = NeonRemoteDatabase(
      gateway: gateway,
      config: _config,
      mapper: mapper,
    );
    final storage = NeonFileStorage(
      gateway: storageGateway,
      signedUrlLifetime: _storageConfig.signedUrlLifetime,
    );

    registry
      ..registerSingleton<NeonConfig>(_config)
      ..registerSingleton<NeonStorageConfig>(_storageConfig)
      ..registerSingleton<NeonSupport>(
        NeonSupport(config: _config, storageConfig: _storageConfig),
      )
      ..registerSingleton<NeonQueryMapper>(mapper)
      ..registerSingleton<PostgrestGateway>(gateway)
      ..registerSingleton<NeonStorageGateway>(storageGateway)
      ..registerSingleton<RemoteDatabase>(database)
      ..registerSingleton<FileStorage>(storage);
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<NeonSupport>().check();
  }

  @override
  Future<void> dispose() async {
    final gateway = _gateway;
    final storageGateway = _storageGateway;
    _gateway = null;
    _storageGateway = null;
    if (gateway is HttpNeonGateway) {
      gateway.close();
    }
    if (storageGateway is S3NeonStorageGateway) {
      storageGateway.close();
    }
  }
}
