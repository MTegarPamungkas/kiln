import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../checks.dart';

/// Flags edits in files marked as generated. Disabled by default (opt-in lint).
final class NoEditGeneratedFiles extends AnalysisRule {
  NoEditGeneratedFiles()
    : super(
        name: code.lowerCaseName,
        description: 'Flags edits in files marked as generated.',
      );

  static const LintCode code = LintCode(
    'no_edit_generated_files',
    'Generated files must not be edited. Change the source and '
        'regenerate instead.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final unit = context.currentUnit;
    if (unit == null) {
      return;
    }
    registry.addCompilationUnit(
      this,
      _Visitor(rule: this, filePath: unit.file.path, source: unit.content),
    );
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor({
    required this.rule,
    required this.filePath,
    required this.source,
  });

  final NoEditGeneratedFiles rule;
  final String filePath;
  final String source;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (isGeneratedSource(filePath: filePath, source: source)) {
      rule.reportAtNode(node);
    }
  }
}
