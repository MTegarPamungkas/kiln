import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import '../../../lib/extensions/{{id.snakeCase()}}/{{id.snakeCase()}}_config.dart';
import '../../../lib/extensions/{{id.snakeCase()}}/{{id.snakeCase()}}_module.dart';

void main() {
  test('module registers its config', () {
    final registry = createTestRegistry();

    const {{id.pascalCase()}}Module().register(registry);

    expect(registry.read<{{id.pascalCase()}}Config>(), isNotNull);
  });
}
