import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/env/build_env.dart';
import 'package:full_stack/extensions/env/env_schema.dart';
import 'package:full_stack/extensions/env/env_x.dart';

BuildEnv _env(Map<String, String> values) {
  return BuildEnv(schema: EnvSchema.defaults, values: values);
}

void main() {
  test('parses URIs', () {
    expect(
      _env(<String, String>{'api_base_url': 'https://api.kiln.dev/v1'})
          .uri('api_base_url')
          .toString(),
      'https://api.kiln.dev/v1',
    );
    expect(_env(const <String, String>{}).uri('api_base_url'), isNull);
    expect(
      () =>
          _env(<String, String>{'api_base_url': 'not a uri'})
              .uri('api_base_url'),
      throwsA(isA<Failure>()),
    );
  });

  test('parses durations and booleans', () {
    final env = _env(const <String, String>{
      'enable_debug_tools': 'false',
      'feature_flags': '45',
    });

    expect(env.boolValue('enable_debug_tools'), isFalse);
    expect(env.duration('feature_flags'), const Duration(seconds: 45));
    expect(() => env.boolValue('feature_flags'), throwsA(isA<Failure>()));
  });

  test('parses enum values', () {
    const allowed = <String, String>{
      'dev': 'development',
      'prod': 'production',
    };
    final env = _env(const <String, String>{'feature_flags': 'prod'});

    expect(env.enumValue('feature_flags', allowed), 'production');
    expect(env.enumValue('api_key', allowed), isNull);
    expect(
      () => env.enumValue('feature_flags', const <String, String>{}),
      throwsA(isA<Failure>()),
    );
  });
}
