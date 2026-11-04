import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_config.dart';

void main() {
  test('defaults use the url, anon key, and schema from the prompts', () {
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

  test('valid configuration returns no Failure', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
    );

    expect(config.validate(), isNull);
  });

  test('a non http/https url is rejected', () {
    const config = SupabaseConfig(url: 'demo.supabase.co', anonKey: 'anon-key');

    final failure = config.validate();

    expect(failure?.code, FailureCode.configurationInvalid);
    expect(failure?.kind, FailureKind.configuration);
  });

  test('an empty anon key is rejected without leaking its value', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: '   ',
    );

    final failure = config.validate();

    expect(failure?.code, FailureCode.configurationMissing);
    expect(failure?.message, isNot(contains('   ')));
  });

  test('a schema with odd characters is rejected', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
      schema: 'public; drop table',
    );

    expect(config.validate()?.code, FailureCode.configurationInvalid);
  });

  test('a redirect without a scheme is rejected', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
      authRedirectUrl: 'auth-callback',
    );

    expect(config.validate()?.code, FailureCode.configurationInvalid);
  });

  test('a zero signed url lifetime is rejected', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
      signedUrlLifetime: Duration.zero,
    );

    expect(config.validate()?.code, FailureCode.configurationInvalid);
  });

  test('a local http url is valid and reports insecure transport', () {
    const config = SupabaseConfig(
      url: 'http://127.0.0.1:54321',
      anonKey: 'anon-key',
    );

    expect(config.validate(), isNull);
    expect(config.isInsecureTransport, isTrue);
  });

  test('an https url is secure transport', () {
    const config = SupabaseConfig(
      url: 'https://demo.supabase.co',
      anonKey: 'anon-key',
    );

    expect(config.isInsecureTransport, isFalse);
  });

  test('copyWith changes only the requested values', () {
    const config = SupabaseConfig.defaults;

    final updated = config.copyWith(schema: 'app', usePkce: false);

    expect(updated.schema, 'app');
    expect(updated.usePkce, isFalse);
    expect(updated.url, config.url);
    expect(updated.storageBucket, config.storageBucket);
  });
}
