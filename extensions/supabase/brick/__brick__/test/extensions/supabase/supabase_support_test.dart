import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_config.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_support.dart';

const SupabaseConfig _config = SupabaseConfig(
  url: 'https://example.supabase.co',
  anonKey: 'anon-key',
  schema: 'public',
);

void main() {
  test('reports supported when the client loads', () async {
    var calls = 0;
    final support = SupabaseSupport(
      config: _config,
      probe: () async => calls++,
    );

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['host'], 'example.supabase.co');
    expect(info.details['schema'], 'public');
    expect(calls, 1);
  });

  test('reports missing configuration as not configured', () async {
    final support = SupabaseSupport(
      config: const SupabaseConfig(url: 'not-a-url', anonKey: ''),
      probe: () async {},
    );

    final info = await support.check();

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().code, FailureCode.configurationMissing);
  });

  test('maps a configuration failure from the client', () async {
    final support = SupabaseSupport(
      config: _config,
      probe: () async => throw const Failure(
        code: FailureCode.configurationInvalid,
        message: 'Bad options',
        kind: FailureKind.configuration,
      ),
    );

    final info = await support.check();

    expect(info.state, SupportState.notConfigured);
    expect(info.message, 'Bad options');
  });

  test('maps an initialization error to unavailable', () async {
    final support = SupabaseSupport(
      config: _config,
      probe: () async => throw StateError('network init failed'),
    );

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);
  });

  test('caches the probe until cleared', () async {
    var calls = 0;
    final support = SupabaseSupport(
      config: _config,
      probe: () async => calls++,
    );

    await support.check();
    await support.check();
    expect(calls, 1);

    support.clear();
    await support.check();
    expect(calls, 2);
  });
}
