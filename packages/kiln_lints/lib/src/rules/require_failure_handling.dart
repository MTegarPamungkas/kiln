import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../checks.dart';

/// Requires feature code to handle or rethrow errors instead of swallowing them.
final class RequireFailureHandling extends AnalysisRule {
  RequireFailureHandling()
    : super(
        name: code.lowerCaseName,
        description:
            'Requires feature code to handle or rethrow errors instead of '
            'swallowing them.',
      );

  static const LintCode code = LintCode(
    'require_failure_handling',
    'An empty catch block swallows errors. Handle the Failure, '
        'rethrow it, or surface it to the user.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final unit = context.currentUnit;
    if (unit == null || !isFeaturePath(libRelativePath(unit.file.path))) {
      return;
    }
    registry.addCatchClause(this, _Visitor(rule: this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor({required this.rule});

  final RequireFailureHandling rule;

  @override
  void visitCatchClause(CatchClause node) {
    if (catchSwallowsErrors(node)) {
      rule.reportAtNode(node);
    }
  }
}
