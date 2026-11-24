import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../checks.dart';
import '../context_helpers.dart';

/// Prefers contracts from the Registry over extension implementations.
final class PreferContractOverImpl extends AnalysisRule {
  PreferContractOverImpl()
    : super(
        name: code.lowerCaseName,
        description:
            'Prefers contracts from the Registry over extension '
            'implementations.',
      );

  static const LintCode code = LintCode(
    'prefer_contract_over_impl',
    'Feature and app code must use contracts from the Registry, not '
        'extension implementations.',
    correctionMessage:
        'Read the kiln_core contract from the Registry instead.',
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
    registry.addImportDirective(
      this,
      _Visitor(
        rule: this,
        filePath: unit.file.path,
        packageName: packageNameForContext(context),
      ),
    );
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor({
    required this.rule,
    required this.filePath,
    required this.packageName,
  });

  final PreferContractOverImpl rule;
  final String filePath;
  final String packageName;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) {
      return;
    }
    final message = extensionImportOutsideExtensionMessage(
      filePath: filePath,
      importUri: uri,
      packageName: packageName,
    );
    if (message != null) {
      rule.reportAtNode(node.uri);
    }
  }
}
