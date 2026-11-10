import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/env/build_env.dart';
import 'package:full_stack/extensions/env/env_schema.dart';
import 'package:full_stack/extensions/env/env_validator.dart';
import 'package:full_stack/extensions/env/gate_env.dart';

Gate _gate(Map<String, String> values) {
  final registry = GetItRegistry();
  final schema = EnvSchema.defaults;
  registry
    ..registerSingleton<EnvSchema>(schema)
    ..registerSingleton<Env>(BuildEnv(schema: schema, values: values))
    ..registerSingleton<EnvValidator>(const EnvValidator());
  return Gate(registry);
}

void main() {
  test('envUri returns the parsed URI', () async {
    final gate = _gate(const <String, String>{
      'api_base_url': 'https://api.kiln.dev/v1',
    });

    final result = await gate.envUri('api_base_url');

    expect(result.valueOrNull?.toString(), 'https://api.kiln.dev/v1');
  });

  test('envUri reports an invalid URI as a configuration failure', () async {
    final gate = _gate(const <String, String>{'api_base_url': 'not a uri'});

    final result = await gate.envUri('api_base_url');

    expect(result.failureOrNull?.code, FailureCode.configurationInvalid);
    expect(result.failureOrNull?.kind, FailureKind.configuration);
  });

  test('envBool and envDuration parse typed values', () async {
    final gate = _gate(const <String, String>{
      'enable_debug_tools': 'false',
      'feature_flags': '45',
    });

    expect((await gate.envBool('enable_debug_tools')).valueOrNull, isFalse);
    expect(
      (await gate.envDuration('feature_flags')).valueOrNull,
      const Duration(seconds: 45),
    );
  });

  test('envEnum maps an allowed value', () async {
    final gate = _gate(const <String, String>{'feature_flags': 'prod'});

    final result = await gate.envEnum<String>(
      'feature_flags',
      const <String, String>{'dev': 'development', 'prod': 'production'},
    );

    expect(result.valueOrNull, 'production');
  });

  test('validateEnv reports missing required keys', () async {
    final gate = _gate(const <String, String>{});

    final result = await gate.validateEnv();

    expect(result.failureOrNull?.code, FailureCode.configurationMissing);
  });

  test('describeEnv redacts secrets', () async {
    final gate = _gate(const <String, String>{
      'api_base_url': 'https://api.kiln.dev',
      'api_key': 'super-secret',
    });

    final summary = gate.describeEnv();

    expect(summary['api_base_url'], 'https://api.kiln.dev');
    expect(summary['api_key'], '[redacted]');
  });
}
