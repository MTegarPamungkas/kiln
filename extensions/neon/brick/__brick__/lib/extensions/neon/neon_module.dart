import 'package:kiln_core/kiln_core.dart';

import 'neon_auth_gateway.dart';
import 'neon_auth_repository.dart';
import 'neon_change_signal.dart';
import 'neon_config.dart';
import 'neon_file_storage.dart';
import 'neon_gateway.dart';
import 'neon_query_mapper.dart';
import 'neon_remote_database.dart';
import 'neon_session_token_provider.dart';
import 'neon_storage_config.dart';
import 'neon_storage_gateway.dart';
import 'neon_support.dart';
import 'neon_token_provider.dart';

/// Registers [AuthRepository], [RemoteDatabase], and [FileStorage] over Neon.
///
/// Auth goes through Neon Auth (Better Auth); database access goes through the
/// Data API (PostgREST) with the signed-in user's JWT (or an anonymous JWT when
/// signed out); files go through Object Storage (S3-compatible). Factories can
/// swap the HTTP gateways for in-memory fakes in tests. An optional
/// [changeSignal] carries out-of-band change hints so `RemoteDatabase.watch`
/// refreshes on push instead of only on the polling interval.
final class NeonModule extends KilnModule {
  NeonModule({
    NeonConfig? config,
    NeonStorageConfig? storageConfig,
    NeonChangeSignal? changeSignal,
    PostgrestGateway Function(NeonConfig config, NeonTokenProvider? tokenProvider)?
    gatewayFactory,
    NeonStorageGateway Function(NeonStorageConfig config)? storageGatewayFactory,
    NeonAuthGateway Function(String authUrl)? authGatewayFactory,
  }) : _config = config ?? NeonConfig.defaults,
       _storageConfig = storageConfig ?? NeonStorageConfig.defaults,
       _changeSignal = changeSignal,
       _gatewayFactory = gatewayFactory ??
           ((config, tokenProvider) =>
               HttpNeonGateway(config: config, tokenProvider: tokenProvider)),
       _storageGatewayFactory = storageGatewayFactory ??
           ((config) => S3NeonStorageGateway(config: config)),
       _authGatewayFactory = authGatewayFactory ??
           ((authUrl) => BetterAuthGateway(authUrl: authUrl));

  final NeonConfig _config;
  final NeonStorageConfig _storageConfig;
  final NeonChangeSignal? _changeSignal;
  final PostgrestGateway Function(NeonConfig config, NeonTokenProvider? tokenProvider)
  _gatewayFactory;
  final NeonStorageGateway Function(NeonStorageConfig config)
  _storageGatewayFactory;
  final NeonAuthGateway Function(String authUrl) _authGatewayFactory;

  PostgrestGateway? _gateway;
  NeonStorageGateway? _storageGateway;
  NeonAuthGateway? _authGateway;

  String get _authUrl {
    final value = _config.authUrl?.trim();
    return value == null || value.isEmpty ? '' : value;
  }

  NeonTokenProvider? _fallbackTokenProvider() {
    if (_config.apiKey.trim().isNotEmpty) {
      return StaticNeonTokenProvider(_config.apiKey);
    }
    if (_authUrl.isNotEmpty) {
      return NeonAnonymousTokenProvider(authUrl: _authUrl);
    }
    return null;
  }

  @override
  String get id => 'neon';

  @override
  Set<String> get provides => const <String>{
    'auth',
    'remote_database',
    'file_storage',
  };

  @override
  void register(Registry registry) {
    final authGateway = _authGatewayFactory(_authUrl);
    _authGateway = authGateway;
    final controller =
        registry.readOrNull<SessionController>() ?? SessionController();
    final auth = NeonAuthRepository(
      gateway: authGateway,
      controller: controller,
    );
    final tokenProvider = NeonSessionTokenProvider(
      auth: authGateway,
      fallback: _fallbackTokenProvider(),
    );
    final gateway = _gatewayFactory(_config, tokenProvider);
    _gateway = gateway;
    final storageGateway = _storageGatewayFactory(_storageConfig);
    _storageGateway = storageGateway;
    final mapper = const NeonQueryMapper();
    final database = NeonRemoteDatabase(
      gateway: gateway,
      config: _config,
      mapper: mapper,
      changeSignal: _changeSignal,
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
      ..registerSingleton<NeonAuthGateway>(authGateway)
      ..registerSingleton<NeonAuthRepository>(auth)
      ..registerSingleton<AuthRepository>(auth)
      ..registerSingleton<RemoteDatabase>(database)
      ..registerSingleton<FileStorage>(storage);
    final signal = _changeSignal;
    if (signal != null) {
      registry.registerSingleton<NeonChangeSignal>(signal);
    }
    if (!registry.isRegistered<SessionController>()) {
      registry.registerSingleton<SessionController>(controller);
    }
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<NeonSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    await registry.read<NeonAuthRepository>().restore();
  }

  @override
  Future<void> dispose() async {
    final gateway = _gateway;
    final storageGateway = _storageGateway;
    final authGateway = _authGateway;
    _gateway = null;
    _storageGateway = null;
    _authGateway = null;
    if (gateway is HttpNeonGateway) {
      gateway.close();
    }
    if (storageGateway is S3NeonStorageGateway) {
      storageGateway.close();
    }
    if (authGateway is BetterAuthGateway) {
      authGateway.close();
    }
  }
}
