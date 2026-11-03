import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../checks.dart';

/// Forbids one extension importing another extension's implementation.
final class NoCrossExtensionImport extends DartLintRule {
  const NoCrossExtensionImport()
    : super(
        code: const LintCode(
          name: 'no_cross_extension_import',
          problemMessage:
              'Extensions must communicate through contracts, not import each '
              'other.',
          correctionMessage:
              'Move the shared type to kiln_core or add a contract capability.',
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
      final message = crossExtensionImportMessage(
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
