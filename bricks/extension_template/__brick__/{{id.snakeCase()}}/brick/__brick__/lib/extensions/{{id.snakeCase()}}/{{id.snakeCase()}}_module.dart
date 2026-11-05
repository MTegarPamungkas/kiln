import 'package:kiln_core/kiln_core.dart';

import '{{id.snakeCase()}}_config.dart';

/// Registers the {{name}} services in the Registry.
final class {{id.pascalCase()}}Module extends KilnModule {
  const {{id.pascalCase()}}Module();

  @override
  String get id => '{{id.snakeCase()}}';

  @override
  Set<String> get provides => const {'{{provides}}'};

  @override
  void register(Registry registry) {
    registry.registerSingleton<{{id.pascalCase()}}Config>(
      {{id.pascalCase()}}Config.defaults,
    );
  }
}
