import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../checks.dart';

/// Prefers contracts from the Registry over extension implementations.
final class PreferContractOverImpl extends DartLintRule {
  const PreferContractOverImpl()
    : super(
        code: const LintCode(
          name: 'prefer_contract_over_impl',
          problemMessage:
              'Feature and app code must use contracts from the Registry, not '
              'extension implementations.',
          correctionMessage:
              'Read the kiln_core contract from the Registry instead.',
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
      final message = extensionImportOutsideExtensionMessage(
        filePath: resolver.path,
        importUri: uri,
        packageName: context.pubspec.name,
      );
      if (message != null) {
        reporter.atNode(node.uri, code);
      }
    });
  }
}
