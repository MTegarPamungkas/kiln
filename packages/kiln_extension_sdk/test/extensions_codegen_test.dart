import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

LockedExtension _entry({List<String> files = const <String>[]}) {
  return LockedExtension(
    version: '0.1.0',
    source: ExtensionSource.bundled,
    files: <String, String>{
      for (final path in files) path: 'sha256:${path.length}',
    },
  );
}

void main() {
  group('ExtensionsCodegen.build', () {
    const codegen = ExtensionsCodegen();

    test('lists every extension that ships a module', () {
      final source = codegen.build(<String, LockedExtension>{
        'bloc': _entry(
          files: const <String>[
            'lib/extensions/bloc/bloc_module.dart',
            'lib/extensions/bloc/bloc_support.dart',
          ],
        ),
        'dio': _entry(
          files: const <String>['lib/extensions/dio/dio_module.dart'],
        ),
      });

      expect(source, contains("import 'bloc/bloc_module.dart';"));
      expect(source, contains('BlocModule(),'));
      expect(source, contains("import 'dio/dio_module.dart';"));
      expect(source, contains('DioModule(),'));
    });

    test('skips a build-time extension that ships no module', () {
      final source = codegen.build(<String, LockedExtension>{
        'codegen': _entry(
          files: const <String>[
            'build.yaml',
            'lib/extensions/codegen/json_converters.dart',
          ],
        ),
        'dio': _entry(
          files: const <String>['lib/extensions/dio/dio_module.dart'],
        ),
      });

      expect(source, isNot(contains('codegen/codegen_module.dart')));
      expect(source, isNot(contains('CodegenModule()')));
      expect(source, contains('DioModule(),'));
    });

    test('stays compilable when nothing ships a module', () {
      final source = codegen.build(<String, LockedExtension>{
        'codegen': _entry(files: const <String>['build.yaml']),
      });

      expect(source, contains('List<KilnModule> kilnModules()'));
      expect(source, isNot(contains("import 'codegen")));
      expect(source, endsWith('  ];\n}\n'));
    });

    test('orders modules by extension id', () {
      final source = codegen.build(<String, LockedExtension>{
        'theme': _entry(
          files: const <String>['lib/extensions/theme/theme_module.dart'],
        ),
        'analytics': _entry(
          files: const <String>[
            'lib/extensions/analytics/analytics_module.dart',
          ],
        ),
      });

      expect(
        source.indexOf('AnalyticsModule'),
        lessThan(source.indexOf('ThemeModule')),
      );
    });
  });
}
