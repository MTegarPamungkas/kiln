import 'package:kiln_core/kiln_core.dart';

import 'build_env.dart';
import 'env_schema.dart';
import 'env_support.dart';
import 'env_validator.dart';

/// Registers the build-time environment and validates required keys.
final class EnvModule extends KilnModule {
  const EnvModule();

  @override
  String get id => 'env';

  @override
  Set<String> get provides => const <String>{'env'};

  @override
  void register(Registry registry) {
    final schema = EnvSchema.defaults;
    final env = BuildEnv(schema: schema);

    registry
      ..registerSingleton<EnvSchema>(schema)
      ..registerSingleton<Env>(env)
      ..registerSingleton<EnvValidator>(const EnvValidator())
      ..registerSingleton<EnvSupport>(EnvSupport(env: env, schema: schema));
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<EnvSupport>().info;
  }

  @override
  void ready(Registry registry) {
    registry.read<EnvValidator>().validate(
      registry.read<Env>(),
      registry.read<EnvSchema>(),
    );
  }
}
