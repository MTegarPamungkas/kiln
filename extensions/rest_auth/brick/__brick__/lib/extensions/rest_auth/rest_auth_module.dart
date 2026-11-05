import 'package:kiln_core/kiln_core.dart';

import 'auth_middleware.dart';
import 'rest_account_management.dart';
import 'rest_auth.dart';
import 'rest_auth_config.dart';
import 'rest_auth_support.dart';
import 'rest_session_bridge.dart';
import 'rest_token_store.dart';
import 'unauthorized_handler.dart';

/// Registers REST auth, its bridge, and the HTTP middleware.
final class RestAuthModule extends KilnModule {
  const RestAuthModule();

  @override
  String get id => 'rest_auth';

  @override
  Set<String> get provides => const <String>{'auth'};

  @override
  Set<String> get requires => const <String>{'http_client', 'secure_storage'};

  @override
  void register(Registry registry) {
    const config = RestAuthConfig.defaults;
    final client = registry.read<HttpClient>();
    final storage = registry.read<SecureStorage>();
    final auth = RestAuth(
      client: client,
      store: RestTokenStore(storage: storage),
      config: config,
      clock: registry.readOrNull<Clock>() ?? const SystemClock(),
    );
    final bridge = RestSessionBridge(
      auth: auth,
      session: registry.read<SessionController>(),
    );

    registry
      ..registerSingleton<RestAuthConfig>(config)
      ..registerSingleton<RestAuthSupport>(
        RestAuthSupport(
          config: config,
          storageProbe: () => storage.read('rest_auth.health'),
        ),
      )
      ..registerSingleton<AuthRepository>(auth)
      ..registerSingleton<TokenProvider>(auth.tokenProvider)
      ..registerSingleton<AccountManagement>(
        RestAccountManagement(auth: auth, config: config),
      )
      ..registerSingleton<RestSessionBridge>(bridge);

    final pipeline = registry.readOrNull<HttpPipeline>();
    if (pipeline != null) {
      pipeline
        ..use(AuthMiddleware(auth.tokenProvider), priority: 10)
        ..use(
          UnauthorizedHandler(
            refresh: auth.refreshAccessToken,
            signOut: auth.signOut,
          ),
          priority: 11,
        );
    }
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<RestAuthSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    try {
      final auth = registry.read<AuthRepository>();
      if (auth is RestAuth) {
        await auth.initialize();
      }
      await registry.read<RestSessionBridge>().start();
    } on Object catch (error) {
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'REST auth session restore failed: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }
}
