import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/env/build_env.dart';
import 'package:full_stack/extensions/env/env_schema.dart';
import 'package:full_stack/extensions/env/env_support.dart';

void main() {
  test('reports supported for a complete environment', () {
    final schema = EnvSchema.defaults;
    final env = BuildEnv(
      schema: schema,
      values: const <String, String>{'api_base_url': 'https://api.kiln.dev'},
    );
    final support = EnvSupport(env: env, schema: schema);

    final info = support.info;

    expect(info.isSupported, isTrue);
    expect(info.details['keys'], isA<List<Object?>>());
  });

  test('reports missing required keys as not configured', () {
    const schema = EnvSchema(
      keys: <EnvKeySpec>[
        EnvKeySpec(
          name: 'required_key',
          type: EnvValueType.string,
          required: true,
        ),
      ],
    );
    final env = BuildEnv(schema: schema, values: const <String, String>{});
    final support = EnvSupport(env: env, schema: schema);

    final info = support.info;

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().code, FailureCode.configurationMissing);
    expect(info.details['missing'], <String>['required_key']);
  });
}
