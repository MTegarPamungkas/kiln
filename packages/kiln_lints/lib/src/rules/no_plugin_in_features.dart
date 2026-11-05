import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../checks.dart';

/// Forbids feature code from importing platform and backend plugins directly.
final class NoPluginInFeatures extends DartLintRule {
  const NoPluginInFeatures()
    : super(
        code: const LintCode(
          name: 'no_plugin_in_features',
          problemMessage:
              'Feature code must not import a plugin directly. '
              'Use a contract from kiln_core.',
          correctionMessage:
              'Add or install an extension that provides the contract.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) {
        return;
      }
      final message = pluginInFeatureMessage(
        filePath: resolver.path,
        importUri: uri,
      );
      if (message != null) {
        reporter.atNode(node.uri, code);
      }
    });
  }
}
