import 'package:kiln_core/kiln_core.dart';

import 'neon_config.dart';
import 'neon_gateway.dart';
import 'neon_query_mapper.dart';
import 'neon_remote_database.dart';
import 'neon_support.dart';

/// Registers [RemoteDatabase] over the Neon Data API (PostgREST).
///
/// The extension provides the `remote_database` slot only; auth, storage, and
/// realtime stay with their own connectors. A [gatewayFactory] can swap the
/// HTTP gateway for an in-memory one in tests.
final class NeonModule extends KilnModule {
  NeonModule({
    NeonConfig? config,
    PostgrestGateway Function(NeonConfig config)? gatewayFactory,
  }) : _config = config ?? NeonConfig.defaults,
       _gatewayFactory =
           gatewayFactory ?? ((config) => HttpNeonGateway(config: config));

  final NeonConfig _config;
  final PostgrestGateway Function(NeonConfig config) _gatewayFactory;
  PostgrestGateway? _gateway;

  @override
  String get id => 'neon';

  @override
  Set<String> get provides => const <String>{'remote_database'};

  @override
  void register(Registry registry) {
    final gateway = _gatewayFactory(_config);
    _gateway = gateway;
    final mapper = const NeonQueryMapper();
    final database = NeonRemoteDatabase(
      gateway: gateway,
      config: _config,
      mapper: mapper,
    );

    registry
      ..registerSingleton<NeonConfig>(_config)
      ..registerSingleton<NeonSupport>(NeonSupport(config: _config))
      ..registerSingleton<NeonQueryMapper>(mapper)
      ..registerSingleton<PostgrestGateway>(gateway)
      ..registerSingleton<RemoteDatabase>(database);
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<NeonSupport>().check();
  }

  @override
  Future<void> dispose() async {
    final gateway = _gateway;
    _gateway = null;
    if (gateway is HttpNeonGateway) {
      gateway.close();
    }
  }
}
