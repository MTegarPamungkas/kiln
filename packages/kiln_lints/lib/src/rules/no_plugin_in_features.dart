import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../checks.dart';

/// Forbids feature code from importing platform and backend plugins directly.
final class NoPluginInFeatures extends AnalysisRule {
  NoPluginInFeatures()
    : super(
        name: code.lowerCaseName,
        description:
            'Forbids feature code from importing platform and backend plugins '
            'directly.',
      );

  static const LintCode code = LintCode(
    'no_plugin_in_features',
    'Feature code must not import a plugin directly. '
        'Use a contract from kiln_core.',
    correctionMessage:
        'Add or install an extension that provides the contract.',
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
      _Visitor(rule: this, filePath: unit.file.path),
    );
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor({required this.rule, required this.filePath});

  final NoPluginInFeatures rule;
  final String filePath;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) {
      return;
    }
    final message = pluginInFeatureMessage(
      filePath: filePath,
      importUri: uri,
    );
    if (message != null) {
      rule.reportAtNode(node.uri);
    }
  }
}
