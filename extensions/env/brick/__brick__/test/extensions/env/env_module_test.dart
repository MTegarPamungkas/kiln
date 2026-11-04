import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/env/env_keys.dart';
import 'package:{{app_name}}/extensions/env/env_module.dart';
import 'package:{{app_name}}/extensions/env/env_schema.dart';
import 'package:{{app_name}}/extensions/env/env_support.dart';
import 'package:{{app_name}}/extensions/env/env_validator.dart';

void main() {
  test('module registers the environment, schema, and validator', () {
    final registry = GetItRegistry();

    const EnvModule().register(registry);

    expect(registry.read<Env>(), isA<Env>());
    expect(registry.read<EnvSchema>().contains(EnvKeys.apiBaseUrl), isTrue);
    expect(registry.read<EnvValidator>(), isA<EnvValidator>());
    expect(registry.read<EnvSupport>(), isA<EnvSupport>());
  });

  test('module reports not configured until required keys are set', () {
    final registry = GetItRegistry();

    const EnvModule().register(registry);

    expect(
      registry.read<EnvSupport>().info.state,
      SupportState.notConfigured,
    );
    expect(
      () => const EnvModule().ready(registry),
      throwsA(isA<Failure>()),
    );
  });
}
