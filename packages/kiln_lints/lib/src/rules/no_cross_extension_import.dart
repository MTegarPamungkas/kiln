import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../checks.dart';
import '../context_helpers.dart';

/// Forbids one extension importing another extension's implementation.
final class NoCrossExtensionImport extends AnalysisRule {
  NoCrossExtensionImport()
    : super(
        name: code.lowerCaseName,
        description:
            'Forbids one extension importing another extension implementation.',
      );

  static const LintCode code = LintCode(
    'no_cross_extension_import',
    'Extensions must communicate through contracts, not import each other.',
    correctionMessage:
        'Move the shared type to kiln_core or add a contract capability.',
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

  final NoCrossExtensionImport rule;
  final String filePath;
  final String packageName;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) {
      return;
    }
    final message = crossExtensionImportMessage(
      filePath: filePath,
      importUri: uri,
      packageName: packageName,
    );
    if (message != null) {
      rule.reportAtNode(node.uri);
    }
  }
}
