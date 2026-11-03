import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/env/env_keys.dart';
import 'package:full_stack/extensions/env/env_module.dart';
import 'package:full_stack/extensions/env/env_schema.dart';
import 'package:full_stack/extensions/env/env_validator.dart';

void main() {
  test('module registers the environment, schema, and validator', () {
    final registry = GetItRegistry();

    const EnvModule().register(registry);
    const EnvModule().ready(registry);

    expect(registry.read<Env>(), isA<Env>());
    expect(registry.read<EnvSchema>().contains(EnvKeys.apiBaseUrl), isTrue);
    expect(registry.read<EnvValidator>(), isA<EnvValidator>());
  });
}
