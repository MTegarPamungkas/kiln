import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/workspace/workspace.dart';
import 'package:kiln_lints/src/rules/no_cross_extension_import.dart';
import 'package:kiln_lints/src/rules/no_edit_generated_files.dart';
import 'package:kiln_lints/src/rules/no_plugin_in_features.dart';
import 'package:kiln_lints/src/rules/prefer_contract_over_impl.dart';
import 'package:kiln_lints/src/rules/require_failure_handling.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _FakePackage implements WorkspacePackage {
  _FakePackage(this.root);

  @override
  final Folder root;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRuleContext implements RuleContext {
  _FakeRuleContext({required this.currentUnit, required this.package});

  @override
  final RuleContextUnit currentUnit;

  @override
  final WorkspacePackage package;

  @override
  LibraryElement? get libraryElement => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DispatchingVisitorRegistry implements RuleVisitorRegistry {
  final List<AstVisitor<void>> _importVisitors = <AstVisitor<void>>[];
  final List<AstVisitor<void>> _unitVisitors = <AstVisitor<void>>[];
  final List<AstVisitor<void>> _catchVisitors = <AstVisitor<void>>[];

  @override
  void addImportDirective(AbstractAnalysisRule rule, AstVisitor<void> visitor) {
    _importVisitors.add(visitor);
  }

  @override
  void addCompilationUnit(AbstractAnalysisRule rule, AstVisitor<void> visitor) {
    _unitVisitors.add(visitor);
  }

  @override
  void addCatchClause(AbstractAnalysisRule rule, AstVisitor<void> visitor) {
    _catchVisitors.add(visitor);
  }

  void run(CompilationUnit unit) {
    for (final visitor in _unitVisitors) {
      unit.accept(visitor);
    }
    unit.visitChildren(
      _TreeDispatcher(
        importVisitors: _importVisitors,
        catchVisitors: _catchVisitors,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TreeDispatcher extends RecursiveAstVisitor<void> {
  _TreeDispatcher({
    required this.importVisitors,
    required this.catchVisitors,
  });

  final List<AstVisitor<void>> importVisitors;
  final List<AstVisitor<void>> catchVisitors;

  @override
  void visitImportDirective(ImportDirective node) {
    for (final visitor in importVisitors) {
      node.accept(visitor);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    for (final visitor in catchVisitors) {
      node.accept(visitor);
    }
    super.visitCatchClause(node);
  }
}

List<Diagnostic> _runRule(
  AnalysisRule rule, {
  required String relativePath,
  required String content,
  String packageName = 'my_app',
}) {
  final provider = MemoryResourceProvider(context: p.posix);
  final rootPath = '/workspace/$packageName';
  provider.newFile(
    '$rootPath/pubspec.yaml',
    'name: $packageName\n',
  );
  final filePath = '$rootPath/$relativePath';
  final file = provider.newFile(filePath, content);

  final parsed = parseString(content: content, path: filePath);
  final listener = RecordingDiagnosticListener();
  final reporter = DiagnosticReporter(listener, FileSource(file));
  rule.reporter = reporter;

  final unitContext = RuleContextUnit(
    file: file,
    content: content,
    diagnosticReporter: reporter,
    unit: parsed.unit,
  );
  final context = _FakeRuleContext(
    currentUnit: unitContext,
    package: _FakePackage(provider.getFolder(rootPath)),
  );
  final registry = _DispatchingVisitorRegistry();
  rule.registerNodeProcessors(registry, context);
  registry.run(parsed.unit);

  return listener.diagnostics;
}

void main() {
  test('NoCrossExtensionImport flags cross-extension imports and allows own', () {
    final bad = _runRule(
      NoCrossExtensionImport(),
      relativePath: 'lib/extensions/dio/client.dart',
      content: "import 'package:my_app/extensions/storage/prefs.dart';\n",
    );
    expect(bad.map((d) => d.diagnosticCode.lowerCaseName), [
      'no_cross_extension_import',
    ]);

    final ok = _runRule(
      NoCrossExtensionImport(),
      relativePath: 'lib/extensions/dio/client.dart',
      content: "import 'package:my_app/extensions/dio/config.dart';\n",
    );
    expect(ok, isEmpty);
  });

  test('PreferContractOverImpl flags extension imports in features', () {
    final bad = _runRule(
      PreferContractOverImpl(),
      relativePath: 'lib/features/home/home_page.dart',
      content: "import 'package:my_app/extensions/dio/dio_client.dart';\n",
    );
    expect(bad.map((d) => d.diagnosticCode.lowerCaseName), [
      'prefer_contract_over_impl',
    ]);

    final ok = _runRule(
      PreferContractOverImpl(),
      relativePath: 'lib/features/home/home_page.dart',
      content: "import 'package:kiln_core/kiln_core.dart';\n",
    );
    expect(ok, isEmpty);
  });

  test('NoPluginInFeatures flags direct plugin imports in features', () {
    final bad = _runRule(
      NoPluginInFeatures(),
      relativePath: 'lib/features/auth/login.dart',
      content: "import 'package:firebase_auth/firebase_auth.dart';\n",
    );
    expect(bad.map((d) => d.diagnosticCode.lowerCaseName), [
      'no_plugin_in_features',
    ]);

    final ok = _runRule(
      NoPluginInFeatures(),
      relativePath: 'lib/extensions/firebase/auth.dart',
      content: "import 'package:firebase_auth/firebase_auth.dart';\n",
    );
    expect(ok, isEmpty);
  });

  test('NoEditGeneratedFiles flags generated files', () {
    final bad = _runRule(
      NoEditGeneratedFiles(),
      relativePath: 'lib/core/extensions.g.dart',
      content: '// GENERATED CODE - DO NOT MODIFY BY HAND\nvoid init() {}\n',
    );
    expect(bad.map((d) => d.diagnosticCode.lowerCaseName), [
      'no_edit_generated_files',
    ]);

    final ok = _runRule(
      NoEditGeneratedFiles(),
      relativePath: 'lib/features/home/home_page.dart',
      content: 'void build() {}\n',
    );
    expect(ok, isEmpty);
  });

  test('RequireFailureHandling flags empty catch in features only', () {
    final bad = _runRule(
      RequireFailureHandling(),
      relativePath: 'lib/features/auth/login.dart',
      content: 'void run() { try {} catch (_) {} }\n',
    );
    expect(bad.map((d) => d.diagnosticCode.lowerCaseName), [
      'require_failure_handling',
    ]);

    final okHandled = _runRule(
      RequireFailureHandling(),
      relativePath: 'lib/features/auth/login.dart',
      content: 'void run() { try {} catch (_) { rethrow; } }\n',
    );
    expect(okHandled, isEmpty);

    final okOutsideFeature = _runRule(
      RequireFailureHandling(),
      relativePath: 'lib/app/bootstrap.dart',
      content: 'void run() { try {} catch (_) {} }\n',
    );
    expect(okOutsideFeature, isEmpty);
  });
}
