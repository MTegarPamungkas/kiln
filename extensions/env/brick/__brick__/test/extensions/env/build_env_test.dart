import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/env/build_env.dart';
import 'package:{{app_name}}/extensions/env/env_keys.dart';
import 'package:{{app_name}}/extensions/env/env_schema.dart';

void main() {
  test('reads only keys declared by the schema', () {
    final env = BuildEnv(
      schema: EnvSchema.defaults,
      values: const <String, String>{
        'api_base_url': 'https://api.kiln.dev',
        'api_key': 'secret',
        'unknown': 'ignored',
      },
    );

    expect(env.read(EnvKeys.apiBaseUrl), 'https://api.kiln.dev');
    expect(env.read(EnvKeys.apiKey), 'secret');
    expect(env.read('unknown'), isNull);
    expect(env.containsKey(EnvKeys.apiBaseUrl), isTrue);
    expect(env.values, isNot(contains('unknown')));
    expect(env.values, containsPair(EnvKeys.apiBaseUrl, 'https://api.kiln.dev'));
  });

  test('treats empty values as absent', () {
    final env = BuildEnv(
      schema: EnvSchema.defaults,
      values: const <String, String>{'api_base_url': ''},
    );

    expect(env.read(EnvKeys.apiBaseUrl), '');
    expect(env.containsKey(EnvKeys.apiBaseUrl), isFalse);
  });
}
