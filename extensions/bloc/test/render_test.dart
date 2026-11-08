import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('bloc brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'bloc_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/app/bloc_providers.dart',
        'lib/extensions/bloc/bloc_module.dart',
        'lib/core/bloc/base_bloc.dart',
        'lib/core/bloc/async_bloc.dart',
        'lib/core/bloc/session_bloc.dart',
        'lib/features/notes/feature.dart',
        'lib/features/notes/domain/entities/note.dart',
        'lib/features/notes/domain/repositories/notes_repository.dart',
        'lib/features/notes/domain/usecases/add_note.dart',
        'lib/features/notes/data/models/note_dto.dart',
        'lib/features/notes/data/datasources/notes_local_datasource.dart',
        'lib/features/notes/data/repositories/notes_repository_impl.dart',
        'lib/features/notes/presentation/bloc/notes_bloc.dart',
        'lib/features/notes/presentation/screens/notes_page.dart',
        'test/features/notes/notes_bloc_test.dart',
      ]),
    );
    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('bloc_module.dart'),
    );
    expect(String.fromCharCodes(module.bytes), contains("'state_bloc'"));
    final paths = files.map((file) => file.relativePath).toList();
    expect(
      paths.where((path) => path.contains('cubit')),
      isEmpty,
      reason: 'the bloc extension must not ship Cubit scaffolding',
    );
  });
}
