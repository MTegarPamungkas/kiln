import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/no_cross_extension_import.dart';
import 'src/rules/no_edit_generated_files.dart';
import 'src/rules/no_plugin_in_features.dart';
import 'src/rules/prefer_contract_over_impl.dart';
import 'src/rules/require_failure_handling.dart';

/// Analyzer plugin that keeps Kiln applications on contracts.
class KilnLintsPlugin extends Plugin {
  KilnLintsPlugin();

  @override
  String get name => 'kiln_lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(NoCrossExtensionImport());
    registry.registerWarningRule(PreferContractOverImpl());
    registry.registerWarningRule(NoPluginInFeatures());
    registry.registerLintRule(NoEditGeneratedFiles());
    registry.registerWarningRule(RequireFailureHandling());
  }
}
