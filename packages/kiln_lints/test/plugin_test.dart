import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:kiln_lints/kiln_lints.dart';
import 'package:kiln_lints/main.dart' as entry;
import 'package:test/test.dart';

class _RecordingPluginRegistry implements PluginRegistry {
  final List<AbstractAnalysisRule> warnings = <AbstractAnalysisRule>[];
  final List<AbstractAnalysisRule> lints = <AbstractAnalysisRule>[];

  @override
  void registerWarningRule(AbstractAnalysisRule rule) {
    warnings.add(rule);
  }

  @override
  void registerLintRule(AbstractAnalysisRule rule) {
    lints.add(rule);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('plugin registers every Kiln lint rule', () {
    final registry = _RecordingPluginRegistry();
    KilnLintsPlugin().register(registry);

    final allNames = <String>[
      ...registry.warnings.map((rule) => rule.name),
      ...registry.lints.map((rule) => rule.name),
    ];

    expect(
      allNames,
      unorderedEquals(<String>[
        'no_cross_extension_import',
        'prefer_contract_over_impl',
        'no_plugin_in_features',
        'no_edit_generated_files',
        'require_failure_handling',
      ]),
    );
  });

  test('entrypoint exposes the Kiln plugin', () {
    expect(entry.plugin, isA<KilnLintsPlugin>());
    expect(entry.plugin.name, 'kiln_lints');
  });

  test('generated-file rule is opt-in lint while others are default warnings', () {
    final registry = _RecordingPluginRegistry();
    KilnLintsPlugin().register(registry);

    expect(
      registry.lints.map((rule) => rule.name),
      equals(<String>['no_edit_generated_files']),
    );
    expect(
      registry.warnings.map((rule) => rule.name),
      unorderedEquals(<String>[
        'no_cross_extension_import',
        'prefer_contract_over_impl',
        'no_plugin_in_features',
        'require_failure_handling',
      ]),
    );
  });
}
