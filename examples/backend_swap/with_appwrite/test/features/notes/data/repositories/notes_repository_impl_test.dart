import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:with_appwrite/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:with_appwrite/features/notes/domain/entities/note.dart';

void main() {
  group('NotesRepositoryImpl', () {
    test('maps backend rows into entities', () async {
      final database = FakeRemoteDatabase();
      await database.create('notes', <String, Object?>{'title': 'Buy milk'});
      final repository = NotesRepositoryImpl(database: database);

      final notes = await repository.fetchNotes();

      expect(notes, hasLength(1));
      expect(notes.single, isA<Note>());
      expect(notes.single.id, isNotEmpty);
      expect(notes.single.body, 'Buy milk');
      expect(notes.single.isDone, isFalse);
    });

    test(
      'reads the optional done and updated_at columns when present',
      () async {
        final database = FakeRemoteDatabase();
        await database.create('notes', <String, Object?>{'title': 'Ship it'});
        final id = (await database.query('notes')).single['id'];
        await database.update('notes', '$id', <String, Object?>{
          'done': true,
          'updated_at': '2026-01-02T03:04:05.000Z',
        });
        final repository = NotesRepositoryImpl(database: database);

        final note = (await repository.fetchNotes()).single;

        expect(note.isDone, isTrue);
        expect(note.updatedAt, DateTime.parse('2026-01-02T03:04:05.000Z'));
      },
    );

    test('falls back to Untitled when the row has no text column', () async {
      final database = FakeRemoteDatabase();
      await database.create('notes', <String, Object?>{});
      final repository = NotesRepositoryImpl(database: database);

      expect((await repository.fetchNotes()).single.body, 'Untitled');
    });

    test('createNote writes only the text column', () async {
      final database = FakeRemoteDatabase();
      final repository = NotesRepositoryImpl(database: database);

      await repository.createNote('Buy milk');

      final row = (await database.query('notes')).single;
      expect(row.keys, containsAll(<String>['id', 'title']));
      expect(row['title'], 'Buy milk');
    });
  });
}
