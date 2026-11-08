import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:with_supabase/app/registry_scope.dart';
import 'package:with_supabase/features/notes/feature.dart';

/// Pumps the page with [database] registered as the only backend.
Future<void> pumpNotesPage(WidgetTester tester, RemoteDatabase database) async {
  final registry = createTestRegistry(remoteDatabase: database);
  registry.registerLazySingleton<NotesRepository>(
    () => notesRepository(registry),
  );
  await tester.pumpWidget(
    RegistryScope(
      registry: registry,
      child: const MaterialApp(home: NotesPage()),
    ),
  );
}

void main() {
  testWidgets('renders the notes returned by the backend', (tester) async {
    final database = FakeRemoteDatabase();
    await database.create('notes', <String, Object?>{'title': 'Buy milk'});

    await pumpNotesPage(tester, database);
    await pumpUntil(tester, () => find.text('Buy milk').evaluate().isNotEmpty);

    expect(find.text('Buy milk'), findsOneWidget);
  });

  testWidgets('shows the empty state before the first note', (tester) async {
    await pumpNotesPage(tester, FakeRemoteDatabase());
    await pumpUntil(
      tester,
      () => find
          .text('No notes yet. Create the first one.')
          .evaluate()
          .isNotEmpty,
    );

    expect(find.text('No notes yet. Create the first one.'), findsOneWidget);
  });

  testWidgets('the create button adds a note through the contract', (
    tester,
  ) async {
    final database = FakeRemoteDatabase();
    await pumpNotesPage(tester, database);
    await pumpUntil(
      tester,
      () => find
          .text('No notes yet. Create the first one.')
          .evaluate()
          .isNotEmpty,
    );

    await tester.tap(find.byType(FilledButton));
    await pumpUntil(
      tester,
      () => find.byIcon(Icons.note_outlined).evaluate().isNotEmpty,
    );

    expect(find.byIcon(Icons.note_outlined), findsOneWidget);
    expect((await database.query('notes')), hasLength(1));
  });

  testWidgets('a backend failure surfaces the retry copy', (tester) async {
    final database = FakeRemoteDatabase()
      ..failure = const Failure(
        code: FailureCode.remoteDatabaseUnavailable,
        message: 'offline',
        kind: FailureKind.network,
      );

    await pumpNotesPage(tester, database);
    await pumpUntil(
      tester,
      () => find.textContaining('Could not load notes').evaluate().isNotEmpty,
    );

    expect(find.textContaining('Could not load notes'), findsOneWidget);
  });
}
