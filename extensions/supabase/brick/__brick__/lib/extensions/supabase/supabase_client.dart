import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_failure_mapper.dart';

/// Creates and caches the Supabase client described by [SupabaseConfig].
///
/// The client is created once through [load]; every gateway uses [client] so
/// there is a single realtime socket, session store, and PKCE store.
final class SupabaseClientProvider {
  SupabaseClientProvider(this.config);

  final SupabaseConfig config;

  SupabaseClient? _client;
  Future<SupabaseClient>? _loading;
  bool _initialized = false;

  bool get isReady => _client != null;

  /// The ready client.
  ///
  /// Throws [Failure] `configuration.missing` when [load] has not run yet; the
  /// module calls it from the `ready` hook before the app uses any contract.
  SupabaseClient get client {
    final client = _client;
    if (client == null) {
      throw const Failure(
        code: FailureCode.configurationMissing,
        message:
            'The Supabase client is not ready. Call SupabaseClientProvider.load().',
        kind: FailureKind.configuration,
      );
    }
    return client;
  }

  /// Prepares the client with the PKCE flow and the SDK session store.
  ///
  /// Concurrent calls share a single initialization.
  Future<SupabaseClient> load() async {
    final ready = _client;
    if (ready != null) {
      return ready;
    }
    final pending = _loading;
    if (pending != null) {
      return pending;
    }
    final problem = config.validate();
    if (problem != null) {
      throw problem;
    }
    final future = _initialize();
    _loading = future;
    try {
      return await future;
    } finally {
      if (_client == null) {
        _loading = null;
      }
    }
  }

  Future<SupabaseClient> _initialize() async {
    try {
      final instance = await Supabase.initialize(
        url: config.url,
        publishableKey: config.anonKey,
        postgrestOptions: PostgrestClientOptions(schema: config.schema),
        authOptions: FlutterAuthClientOptions(
          authFlowType: config.usePkce
              ? AuthFlowType.pkce
              : AuthFlowType.implicit,
          autoRefreshToken: config.autoRefreshToken,
          persistSession: config.persistSession,
          detectSessionInUri: config.detectSessionInUri,
        ),
      );
      _initialized = true;
      return _client = instance.client;
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.configurationInvalid,
        fallbackKind: FailureKind.configuration,
      );
    }
  }

  /// Closes the client, its realtime socket, and the token auto refresh.
  Future<void> dispose() async {
    _client = null;
    _loading = null;
    if (!_initialized) {
      return;
    }
    _initialized = false;
    await Supabase.instance.dispose();
  }
}
