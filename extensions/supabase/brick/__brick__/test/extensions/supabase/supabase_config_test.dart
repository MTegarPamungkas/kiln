import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_config.dart';

void main() {
  test('nilai bawaan memakai url, anon key, dan schema dari prompt', () {
    const config = SupabaseConfig.defaults;

    expect(config.url, '{{{url}}}');
    expect(config.anonKey, isNotEmpty);
    expect(config.schema, '{{{schema}}}');
    expect(config.storageBucket, 'public');
    expect(config.usePkce, isTrue);
    expect(config.autoRefreshToken, isTrue);
    expect(config.persistSession, isTrue);
    expect(config.detectSessionInUri, isFalse);
    expect(config.signedUrlLifetime, const Duration(hours: 1));
    expect(config.redirectUri.toString(), 'kiln-auth://auth-callback');
  });

  test('konfigurasi valid tidak mengembalikan Failure', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
    );

    expect(config.validate(), isNull);
  });

  test('url bukan http/https ditolak', () {
    const config = SupabaseConfig(url: 'demo.supabase.co', anonKey: 'anon-key');

    final failure = config.validate();

    expect(failure?.code, FailureCode.configurationInvalid);
    expect(failure?.kind, FailureKind.configuration);
  });

  test('anon key kosong ditolak tanpa membocorkan nilainya', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: '   ',
    );

    final failure = config.validate();

    expect(failure?.code, FailureCode.configurationMissing);
    expect(failure?.message, isNot(contains('   ')));
  });

  test('schema dengan karakter aneh ditolak', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
      schema: 'public; drop table',
    );

    expect(config.validate()?.code, FailureCode.configurationInvalid);
  });

  test('redirect tanpa scheme ditolak', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
      authRedirectUrl: 'auth-callback',
    );

    expect(config.validate()?.code, FailureCode.configurationInvalid);
  });

  test('masa berlaku signed URL nol ditolak', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
      signedUrlLifetime: Duration.zero,
    );

    expect(config.validate()?.code, FailureCode.configurationInvalid);
  });

  test('copyWith mengganti hanya nilai yang diminta', () {
    const config = SupabaseConfig.defaults;

    final updated = config.copyWith(schema: 'app', usePkce: false);

    expect(updated.schema, 'app');
    expect(updated.usePkce, isFalse);
    expect(updated.url, config.url);
    expect(updated.storageBucket, config.storageBucket);
  });
}
