import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/env/build_env.dart';
import 'package:full_stack/extensions/env/env_schema.dart';
import 'package:full_stack/extensions/env/env_validator.dart';

void main() {
  test('reports every missing required key in one Failure', () {
    const schema = EnvSchema(
      keys: <EnvKeySpec>[
        EnvKeySpec(name: 'first', type: EnvValueType.string, required: true),
        EnvKeySpec(name: 'second', type: EnvValueType.string, required: true),
        EnvKeySpec(name: 'optional', type: EnvValueType.string),
      ],
    );
    final env = BuildEnv(schema: schema, values: const <String, String>{});

    expect(
      () => const EnvValidator().validate(env, schema),
      throwsA(
        isA<Failure>()
            .having(
              (failure) => failure.code,
              'code',
              FailureCode.configurationMissing,
            )
            .having(
              (failure) => (failure.details['missing'] as List<Object?>),
              'missing',
              <String>['first', 'second'],
            ),
      ),
    );
  });

  test('accepts a complete environment', () {
    final schema = EnvSchema.defaults;
    final env = BuildEnv(
      schema: schema,
      values: const <String, String>{'api_base_url': 'https://api.kiln.dev'},
    );

    expect(() => const EnvValidator().validate(env, schema), returnsNormally);
  });
}
