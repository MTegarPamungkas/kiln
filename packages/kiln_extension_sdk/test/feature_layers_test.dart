import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

String _path(String feature, FeatureLayer layer, String file) =>
    'lib/features/$feature/${layer.name}/$file';

Map<String, String> _single({
  required String feature,
  required FeatureLayer layer,
  required String file,
  required List<String> imports,
}) {
  final buffer = StringBuffer();
  for (final import in imports) {
    buffer.writeln("import '$import';");
  }
  buffer.writeln('void main() {}');
  return <String, String>{_path(feature, layer, file): buffer.toString()};
}

void main() {
  group('layer direction', () {
    test('flags domain importing data', () {
      final violations = layerViolations(
        sourcesByPath: _single(
          feature: 'notes',
          layer: FeatureLayer.domain,
          file: 'usecases/add_note.dart',
          imports: <String>[
            'package:app/features/notes/data/repositories/notes_repository_impl.dart',
          ],
        ),
        packageName: 'app',
      );

      expect(violations, hasLength(1));
      expect(violations.single.message, contains('domain/ must not import'));
    });

    test('flags domain importing presentation', () {
      final violations = layerViolations(
        sourcesByPath: _single(
          feature: 'notes',
          layer: FeatureLayer.domain,
          file: 'entities/note.dart',
          imports: <String>[
            '../../presentation/screens/notes_page.dart',
          ],
        ),
        packageName: 'app',
      );

      expect(violations.single.message, contains('domain/ must not import'));
    });

    test('flags data importing presentation', () {
      final violations = layerViolations(
        sourcesByPath: _single(
          feature: 'notes',
          layer: FeatureLayer.data,
          file: 'repositories/notes_repository_impl.dart',
          imports: <String>[
            'package:app/features/notes/presentation/bloc/notes_bloc.dart',
          ],
        ),
        packageName: 'app',
      );

      expect(violations.single.message, contains('data/ must not import'));
    });

    test('flags presentation reaching into data', () {
      final violations = layerViolations(
        sourcesByPath: _single(
          feature: 'notes',
          layer: FeatureLayer.presentation,
          file: 'bloc/notes_bloc.dart',
          imports: <String>[
            '../../data/datasources/notes_local_datasource.dart',
          ],
        ),
        packageName: 'app',
      );

      expect(violations.single.message, contains('not data/'));
    });

    test('allows the inward direction', () {
      final violations = layerViolations(
        sourcesByPath: <String, String>{
          _path('notes', FeatureLayer.presentation, 'bloc/notes_bloc.dart'):
              "import 'package:app/features/notes/domain/usecases/add_note.dart';\n",
          _path(
            'notes',
            FeatureLayer.data,
            'repositories/notes_repository_impl.dart',
          ): "import 'package:app/features/notes/domain/entities/note.dart';\n",
          _path('notes', FeatureLayer.domain, 'usecases/add_note.dart'):
              "import '../repositories/notes_repository.dart';\n",
        },
        packageName: 'app',
      );

      expect(violations, isEmpty);
    });
  });

  group('framework purity', () {
    test('flags Flutter inside domain', () {
      final violations = layerViolations(
        sourcesByPath: _single(
          feature: 'notes',
          layer: FeatureLayer.domain,
          file: 'entities/note.dart',
          imports: <String>['package:flutter/widgets.dart'],
        ),
        packageName: 'app',
      );

      expect(violations.single.message, contains('framework-free'));
    });

    test('leaves presentation free to use Flutter', () {
      final violations = layerViolations(
        sourcesByPath: _single(
          feature: 'notes',
          layer: FeatureLayer.presentation,
          file: 'screens/notes_page.dart',
          imports: <String>['package:flutter/material.dart'],
        ),
        packageName: 'app',
      );

      expect(violations, isEmpty);
    });
  });

  group('feature isolation', () {
    test('flags reaching into another feature layer', () {
      final violations = layerViolations(
        sourcesByPath: _single(
          feature: 'notes',
          layer: FeatureLayer.presentation,
          file: 'screens/notes_page.dart',
          imports: <String>[
            'package:app/features/orders/domain/entities/order.dart',
          ],
        ),
        packageName: 'app',
      );

      expect(violations.single.message, contains('feature "orders"'));
    });

    test('allows the other feature barrel', () {
      final violations = layerViolations(
        sourcesByPath: _single(
          feature: 'notes',
          layer: FeatureLayer.presentation,
          file: 'screens/notes_page.dart',
          imports: <String>['package:app/features/orders/feature.dart'],
        ),
        packageName: 'app',
      );

      expect(violations, isEmpty);
    });

    test('never reports the composition barrel itself', () {
      final violations = layerViolations(
        sourcesByPath: <String, String>{
          'lib/features/notes/feature.dart':
              "import 'package:app/features/notes/data/repositories/notes_repository_impl.dart';\n"
              "import 'package:app/features/notes/presentation/bloc/notes_bloc.dart';\n",
        },
        packageName: 'app',
      );

      expect(violations, isEmpty);
    });
  });

  test('ignores external packages and files outside features', () {
    final violations = layerViolations(
      sourcesByPath: <String, String>{
        'lib/app/app_shell.dart':
            "import 'package:app/features/notes/feature.dart';\n",
        'lib/core/architecture/use_case.dart':
            "import 'package:kiln_core/kiln_core.dart';\n",
        'lib/extensions/bloc/bloc_module.dart':
            "import 'package:flutter_bloc/flutter_bloc.dart';\n",
        'test/features/notes/x_test.dart':
            "import 'package:app/features/notes/data/models/note_dto.dart';\n",
        _path('notes', FeatureLayer.data, 'datasources/notes_local.dart'):
            "import 'dart:async';\nimport 'package:kiln_core/kiln_core.dart';\n",
      },
      packageName: 'app',
    );

    expect(violations, isEmpty);
  });

  test('resolves exports as well as imports', () {
    final violations = layerViolations(
      sourcesByPath: <String, String>{
        _path('notes', FeatureLayer.domain, 'entities/note.dart'):
            "export 'package:app/features/notes/data/models/note_dto.dart';\n",
      },
      packageName: 'app',
    );

    expect(violations.single.importUri, contains('note_dto.dart'));
  });
}
