import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/env/build_env.dart';
import 'package:{{app_name}}/extensions/env/env_describe.dart';
import 'package:{{app_name}}/extensions/env/env_schema.dart';

void main() {
  test('masks secret values and keeps other values', () {
    final env = BuildEnv(
      schema: EnvSchema.defaults,
      values: const <String, String>{
        'api_base_url': 'https://api.kiln.dev',
        'api_key': 'super-secret',
      },
    );

    final summary = const EnvDescribe().summarize(env, EnvSchema.defaults);

    expect(summary['api_base_url'], 'https://api.kiln.dev');
    expect(summary['api_key'], '[redacted]');
    expect(summary['feature_flags'], '');
  });

  test('keeps an empty secret empty', () {
    final env = BuildEnv(
      schema: EnvSchema.defaults,
      values: const <String, String>{'api_key': ''},
    );

    expect(
      const EnvDescribe().summarize(env, EnvSchema.defaults)['api_key'],
      '',
    );
  });
}
