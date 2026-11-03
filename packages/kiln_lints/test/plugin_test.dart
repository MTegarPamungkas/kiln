// ignore_for_file: invalid_use_of_internal_member

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:kiln_lints/kiln_lints.dart';
import 'package:test/test.dart';

void main() {
  test('plugin exposes every Kiln lint rule', () {
    final rules = KilnLintsPlugin().getLintRules(
      CustomLintConfigs.empty,
    );

    expect(
      rules.map((rule) => rule.code.name),
      containsAll(<String>[
        'no_cross_extension_import',
        'prefer_contract_over_impl',
        'no_plugin_in_features',
        'no_edit_generated_files',
        'require_failure_handling',
      ]),
    );
  });

  test('createPlugin returns the Kiln plugin', () {
    expect(createPlugin(), isA<KilnLintsPlugin>());
  });

  test('generated-file rule is opt-in', () {
    final rules = KilnLintsPlugin().getLintRules(
      CustomLintConfigs.empty,
    );
    final generated = rules.firstWhere(
      (rule) => rule.code.name == 'no_edit_generated_files',
    );

    expect(generated.enabledByDefault, isFalse);
  });
}
