import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:kiln_lints/src/checks.dart';
import 'package:test/test.dart';

final class _CatchFinder extends RecursiveAstVisitor<void> {
  final List<CatchClause> clauses = <CatchClause>[];

  @override
  void visitCatchClause(CatchClause node) {
    clauses.add(node);
    super.visitCatchClause(node);
  }
}

void main() {
  group('cross extension imports', () {
    test('blocks package imports between different extensions', () {
      expect(
        crossExtensionImportMessage(
          filePath: '/app/lib/extensions/http_retry/retry.dart',
          importUri: 'package:app/extensions/dio/dio_module.dart',
          packageName: 'app',
        ),
        isNotNull,
      );
    });

    test('allows imports inside the same extension', () {
      expect(
        crossExtensionImportMessage(
          filePath: '/app/lib/extensions/http_retry/retry.dart',
          importUri: 'package:app/extensions/http_retry/settings.dart',
          packageName: 'app',
        ),
        isNull,
      );
    });

    test('blocks relative imports that cross extension folders', () {
      expect(
        crossExtensionImportMessage(
          filePath: '/app/lib/extensions/http_retry/retry.dart',
          importUri: '../dio/dio_module.dart',
          packageName: 'app',
        ),
        isNotNull,
      );
    });

    test('ignores files outside extensions', () {
      expect(
        crossExtensionImportMessage(
          filePath: '/app/lib/app/app_shell.dart',
          importUri: 'package:app/extensions/dio/dio_module.dart',
          packageName: 'app',
        ),
        isNull,
      );
    });
  });

  group('prefer contract', () {
    test('blocks extension imports from features and app code', () {
      for (final path in <String>[
        '/app/lib/features/orders/orders_page.dart',
        '/app/lib/app/app_shell.dart',
        '/app/lib/core/clock.dart',
      ]) {
        expect(
          extensionImportOutsideExtensionMessage(
            filePath: path,
            importUri: 'package:app/extensions/storage/storage_module.dart',
            packageName: 'app',
          ),
          isNotNull,
          reason: path,
        );
      }
    });

    test('allows contracts from kiln_core', () {
      expect(
        extensionImportOutsideExtensionMessage(
          filePath: '/app/lib/features/orders/orders_page.dart',
          importUri: 'package:kiln_core/kiln_core.dart',
          packageName: 'app',
        ),
        isNull,
      );
    });
  });

  group('plugins in features', () {
    test('blocks plugin imports from features', () {
      expect(
        pluginInFeatureMessage(
          filePath: '/app/lib/features/orders/orders_page.dart',
          importUri: 'package:dio/dio.dart',
        ),
        isNotNull,
      );
      expect(
        pluginInFeatureMessage(
          filePath: '/app/lib/features/orders/orders_page.dart',
          importUri: 'package:firebase_auth/firebase_auth.dart',
        ),
        isNotNull,
      );
    });

    test('allows plugins inside extensions and contracts elsewhere', () {
      expect(
        pluginInFeatureMessage(
          filePath: '/app/lib/extensions/dio/dio_client.dart',
          importUri: 'package:dio/dio.dart',
        ),
        isNull,
      );
      expect(
        pluginInFeatureMessage(
          filePath: '/app/lib/features/orders/orders_page.dart',
          importUri: 'package:kiln_core/kiln_core.dart',
        ),
        isNull,
      );
    });
  });

  group('generated files', () {
    test('detects generated paths and headers', () {
      expect(
        isGeneratedSource(
          filePath: '/app/lib/extensions/extensions.g.dart',
          source: '',
        ),
        isTrue,
      );
      expect(
        isGeneratedSource(
          filePath: '/app/lib/l10n/generated/app_localizations.dart',
          source: '',
        ),
        isTrue,
      );
      expect(
        isGeneratedSource(
          filePath: '/app/lib/features/orders/orders_page.dart',
          source: '// GENERATED CODE - DO NOT MODIFY BY HAND',
        ),
        isTrue,
      );
      expect(
        isGeneratedSource(
          filePath: '/app/lib/features/orders/orders_page.dart',
          source: 'class OrdersPage {}',
        ),
        isFalse,
      );
    });
  });

  group('failure handling', () {
    test('flags empty and commented catch blocks', () {
      final parsed = parseString(
        content: '''
void a() {
  try { a(); } catch (_) {}
}
void b() {
  try { b(); } catch (_) {
    // ignore
  }
}
void c() {
  try { c(); } catch (error) { rethrow; }
}
''',
      );
      final finder = _CatchFinder();
      parsed.unit.accept(finder);

      expect(finder.clauses, hasLength(3));
      expect(catchSwallowsErrors(finder.clauses[0]), isTrue);
      expect(catchSwallowsErrors(finder.clauses[1]), isTrue);
      expect(catchSwallowsErrors(finder.clauses[2]), isFalse);
    });
  });
}
