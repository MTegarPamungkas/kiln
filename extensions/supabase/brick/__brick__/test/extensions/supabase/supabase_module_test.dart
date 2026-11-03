import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/supabase/postgrest_gateway.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_auth_repository.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_config.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_file_storage.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_link_handler.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_module.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_remote_database.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_session_bridge.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_token_provider.dart';

void main() {
  test('module declares the supabase capabilities', () {
    const module = SupabaseModule();

    expect(module.id, 'supabase');
    expect(
      module.provides,
      containsAll(<String>[
        'auth',
        'social_auth',
        'remote_database',
        'file_storage',
      ]),
    );
    expect(module.optionalRequires, contains('deep_links'));
  });

  test('module registers every contract and gateway', () {
    final registry = GetItRegistry()
      ..registerSingleton<SessionController>(SessionController());

    const SupabaseModule().register(registry);

    expect(registry.read<AuthRepository>(), isA<SupabaseAuthRepository>());
    expect(registry.read<SocialAuth>(), isA<SupabaseSocialAuth>());
    expect(registry.read<AccountManagement>(), isA<AccountManagement>());
    expect(registry.read<TokenProvider>(), isA<SupabaseTokenProvider>());
    expect(registry.read<RemoteDatabase>(), isA<SupabaseRemoteDatabase>());
    expect(registry.read<FileStorage>(), isA<SupabaseFileStorage>());
    expect(registry.read<SupabaseConfig>(), isA<SupabaseConfig>());
    expect(registry.read<PostgrestGateway>(), isA<PostgrestGateway>());
    expect(
      registry.read<SupabaseSessionBridge>(),
      isA<SupabaseSessionBridge>(),
    );
    expect(registry.read<SupabaseLinkHandler>(), isA<SupabaseLinkHandler>());
  });

  test('module attaches the link handler when DeepLinks is available', () {
    final registry = GetItRegistry()
      ..registerSingleton<SessionController>(SessionController())
      ..registerSingleton<DeepLinks>(_FakeDeepLinks());

    const SupabaseModule().register(registry);

    final handler = registry.read<SupabaseLinkHandler>();
    expect(handler.isAttached, isFalse);
  });

  test('module falls back to a new SessionController when none exists', () {
    final registry = GetItRegistry();

    const SupabaseModule().register(registry);

    expect(
      registry.read<SupabaseSessionBridge>(),
      isA<SupabaseSessionBridge>(),
    );
  });
}

final class _FakeDeepLinks implements DeepLinks {
  @override
  Uri? get initialLink => null;

  @override
  Stream<Uri> get links => const Stream<Uri>.empty();

  @override
  Future<void> dispose() async {}
}
