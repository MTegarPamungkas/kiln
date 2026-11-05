import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../checks.dart';

/// Flags edits in files marked as generated. Disabled by default.
final class NoEditGeneratedFiles extends DartLintRule {
  const NoEditGeneratedFiles()
    : super(
        code: const LintCode(
          name: 'no_edit_generated_files',
          problemMessage:
              'Generated files must not be edited. Change the source and '
              'regenerate instead.',
        ),
      );

  @override
  bool get enabledByDefault => false;

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      if (isGeneratedSource(
        filePath: resolver.path,
        source: resolver.source.contents.data,
      )) {
        reporter.atNode(unit, code);
      }
    });
  }
}
