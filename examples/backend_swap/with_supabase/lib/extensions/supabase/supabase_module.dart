import 'package:kiln_core/kiln_core.dart';

import 'postgrest_gateway.dart';
import 'supabase_account_management.dart';
import 'supabase_auth_repository.dart';
import 'supabase_client.dart';
import 'supabase_config.dart';
import 'supabase_file_storage.dart';
import 'supabase_gateway.dart';
import 'supabase_link_handler.dart';
import 'supabase_query_mapper.dart';
import 'supabase_realtime_gateway.dart';
import 'supabase_remote_database.dart';
import 'supabase_session_bridge.dart';
import 'supabase_storage_gateway.dart';
import 'supabase_token_provider.dart';

/// Registers Supabase auth, social_auth, remote_database, and file_storage.
///
/// Every contract shares one client and one gateway, so sessions, tokens, and
/// the realtime connection always stay consistent.
final class SupabaseModule extends KilnModule {
  const SupabaseModule();

  @override
  String get id => 'supabase';

  @override
  Set<String> get provides => const <String>{
    'auth',
    'social_auth',
    'remote_database',
    'file_storage',
  };

  @override
  Set<String> get optionalRequires => const <String>{'deep_links'};

  @override
  void register(Registry registry) {
    const config = SupabaseConfig.defaults;
    final provider = SupabaseClientProvider(config);
    final gateway = SdkSupabaseGateway(provider: provider);
    final auth = SupabaseAuthRepository(
      gateway: gateway,
      redirectUri: config.redirectUri,
    );
    final social = SupabaseSocialAuth(gateway: gateway, config: config);
    final account = SupabaseAccountManagement(
      gateway: gateway,
      redirectUri: config.redirectUri,
    );
    final tokenProvider = SupabaseTokenProvider(gateway: gateway);
    final mapper = const SupabaseQueryMapper();
    final postgrest = SdkPostgrestGateway(provider: provider);
    final realtime = SdkSupabaseRealtimeGateway(
      provider: provider,
      schema: config.schema,
    );
    final database = SupabaseRemoteDatabase(
      postgrest: postgrest,
      realtime: realtime,
      mapper: mapper,
    );
    final storageGateway = SdkSupabaseStorageGateway(
      provider: provider,
      bucket: config.storageBucket,
    );
    final storage = SupabaseFileStorage(
      gateway: storageGateway,
      signedUrlLifetime: config.signedUrlLifetime,
    );
    final controller =
        registry.readOrNull<SessionController>() ?? SessionController();
    final bridge = SupabaseSessionBridge(auth: auth, controller: controller);
    final linkHandler = SupabaseLinkHandler(
      gateway: gateway,
      deepLinks: registry.readOrNull<DeepLinks>(),
    );

    registry
      ..registerSingleton<SupabaseConfig>(config)
      ..registerSingleton<SupabaseClientProvider>(provider)
      ..registerSingleton<SupabaseGateway>(gateway)
      ..registerSingleton<SupabaseQueryMapper>(mapper)
      ..registerSingleton<PostgrestGateway>(postgrest)
      ..registerSingleton<SupabaseRealtimeGateway>(realtime)
      ..registerSingleton<SupabaseStorageGateway>(storageGateway)
      ..registerSingleton<SupabaseAuthRepository>(auth)
      ..registerSingleton<AuthRepository>(auth)
      ..registerSingleton<SupabaseSocialAuth>(social)
      ..registerSingleton<SocialAuth>(social)
      ..registerSingleton<AccountManagement>(account)
      ..registerSingleton<TokenProvider>(tokenProvider)
      ..registerSingleton<RemoteDatabase>(database)
      ..registerSingleton<FileStorage>(storage)
      ..registerSingleton<SupabaseSessionBridge>(bridge)
      ..registerSingleton<SupabaseLinkHandler>(linkHandler);
  }

  @override
  Future<void> ready(Registry registry) async {
    await registry.read<SupabaseClientProvider>().load();
    await registry.read<SupabaseAuthRepository>().restore();
    registry.read<SupabaseSessionBridge>().start();
    await registry.read<SupabaseLinkHandler>().start();
  }
}
