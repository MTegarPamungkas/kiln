import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/no_cross_extension_import.dart';
import 'src/rules/no_edit_generated_files.dart';
import 'src/rules/no_plugin_in_features.dart';
import 'src/rules/prefer_contract_over_impl.dart';
import 'src/rules/require_failure_handling.dart';

/// Entry point used by custom_lint to load the plugin.
PluginBase createPlugin() => KilnLintsPlugin();

/// Custom lint rules that keep Kiln applications on contracts.
class KilnLintsPlugin extends PluginBase {
  KilnLintsPlugin();

  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return const <LintRule>[
      NoCrossExtensionImport(),
      PreferContractOverImpl(),
      NoPluginInFeatures(),
      NoEditGeneratedFiles(),
      RequireFailureHandling(),
    ];
  }
}
