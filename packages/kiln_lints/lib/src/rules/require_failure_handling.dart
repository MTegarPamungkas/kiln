import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../checks.dart';

/// Requires feature code to handle or rethrow errors instead of swallowing them.
final class RequireFailureHandling extends DartLintRule {
  const RequireFailureHandling()
    : super(
        code: const LintCode(
          name: 'require_failure_handling',
          problemMessage:
              'An empty catch block swallows errors. Handle the Failure, '
              'rethrow it, or surface it to the user.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (!isFeaturePath(libRelativePath(resolver.path))) {
      return;
    }
    context.registry.addCatchClause((node) {
      if (catchSwallowsErrors(node)) {
        reporter.atNode(node, code);
      }
    });
  }
}
