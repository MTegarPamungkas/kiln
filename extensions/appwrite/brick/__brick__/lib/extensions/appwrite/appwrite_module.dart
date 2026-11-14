import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_account.dart';
import 'appwrite_account_management.dart';
import 'appwrite_auth.dart';
import 'appwrite_client_factory.dart';
import 'appwrite_config.dart';
import 'appwrite_database_gateway.dart';
import 'appwrite_file_storage.dart';
import 'appwrite_functions.dart';
import 'appwrite_remote_database.dart';
import 'appwrite_realtime_gateway.dart';
import 'appwrite_session_bridge.dart';
import 'appwrite_social_auth.dart';
import 'appwrite_storage_gateway.dart';
import 'appwrite_support.dart';

/// Registers AuthRepository, SocialAuth, RemoteDatabase, FileStorage, and
/// CloudFunctions for Appwrite.
final class AppwriteModule extends KilnModule {
  AppwriteModule({
    this.config = AppwriteConfig.defaults,
    this.flavor = AppFlavor.production,
    this.clientFactory = const AppwriteClientFactory(),
  });

  /// Connection settings rendered from the install prompts.
  final AppwriteConfig config;

  /// Flavor that decides whether self-signed certificates are accepted.
  final AppFlavor flavor;

  /// Factory kept injectable so an app can preconfigure the client.
  final AppwriteClientFactory clientFactory;

  AppwriteSessionBridge? _bridge;
  AppwriteRealtimeGateway? _realtime;
  AppwriteAuth? _auth;

  @override
  String get id => 'appwrite';

  @override
  Set<String> get provides => const <String>{
    'auth',
    'social_auth',
    'remote_database',
    'file_storage',
    'functions',
    'token_provider',
    'account_management',
  };

  @override
  void register(Registry registry) {
    final support = AppwriteSupport(config: config);
    final client = clientFactory.create(config: config, flavor: flavor);
    final account = SdkAppwriteAccount(
      account: appwrite.Account(client),
      client: client,
    );
    final tokens = AppwriteTokenProvider(account: account);
    final bridge = AppwriteSessionBridge(
      controller: registry.readOrNull<SessionController>(),
      tokenProvider: tokens,
    );
    final auth = AppwriteAuth(account: account, bridge: bridge);
    _auth = auth;
    final accountManagement = AppwriteAccountManagement(account: account);
    final social = AppwriteSocialAuth(
      account: account,
      config: config,
      bridge: bridge,
    );

    final databaseGateway = SdkAppwriteDatabaseGateway(
      tables: appwrite.TablesDB(client),
      databaseId: config.databaseId,
    );
    final realtime = SdkAppwriteRealtimeGateway(
      realtime: appwrite.Realtime(client),
      database: databaseGateway,
      databaseId: config.databaseId,
    );
    final database = AppwriteRemoteDatabase(
      gateway: databaseGateway,
      realtime: realtime,
    );

    final storage = AppwriteFileStorage(
      gateway: SdkAppwriteStorageGateway(
        client: client,
        storage: appwrite.Storage(client),
        config: config,
      ),
    );

    final functions = AppwriteFunctions(
      functions: appwrite.Functions(client),
    );

    _bridge = bridge;
    _realtime = realtime;

    registry
      ..registerSingleton<AppwriteConfig>(config)
      ..registerSingleton<AppwriteSupport>(support)
      ..registerSingleton<AuthRepository>(auth)
      ..registerSingleton<AppwriteSocialAuth>(social)
      ..registerSingleton<SocialAuth>(social)
      ..registerSingleton<AccountManagement>(accountManagement)
      ..registerSingleton<RemoteDatabase>(database)
      ..registerSingleton<FileStorage>(storage)
      ..registerSingleton<CloudFunctions>(functions)
      ..registerSingleton<TokenProvider>(tokens);
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<AppwriteSupport>().info;
  }

  @override
  Future<void> ready(Registry registry) async {
    try {
      await _auth?.restoreSession();
    } on Object catch (error) {
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Appwrite session restore failed: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _realtime?.dispose();
    await _bridge?.dispose();
    _realtime = null;
    _bridge = null;
  }
}
