import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('riverpod brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'riverpod_app'});
    final paths = files.map((file) => file.relativePath).toList();

    expect(
      paths,
      containsAll(<String>[
        'lib/app/provider_root.dart',
        'lib/extensions/riverpod/riverpod_module.dart',
        'lib/core/riverpod/kiln_providers.dart',
        'lib/core/riverpod/session_notifier.dart',
        'lib/features/notes/feature.dart',
        'lib/features/notes/domain/entities/note.dart',
        'lib/features/notes/domain/repositories/notes_repository.dart',
        'lib/features/notes/domain/usecases/add_note.dart',
        'lib/features/notes/data/models/note_dto.dart',
        'lib/features/notes/data/datasources/notes_local_datasource.dart',
        'lib/features/notes/data/repositories/notes_repository_impl.dart',
        'lib/features/notes/presentation/providers/notes_controller.dart',
        'lib/features/notes/presentation/providers/notes_providers.dart',
        'lib/features/notes/presentation/screens/notes_page.dart',
        'test/features/notes/notes_controller_test.dart',
      ]),
    );
    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('riverpod_module.dart'),
    );
    expect(String.fromCharCodes(module.bytes), contains("'state_riverpod'"));
  });
}
