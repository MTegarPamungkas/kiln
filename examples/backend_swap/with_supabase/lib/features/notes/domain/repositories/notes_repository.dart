import '../entities/note.dart';

/// Contract the presentation layer depends on.
///
/// The implementation lives in `data/`; nothing outside this feature needs to
/// know where notes are stored, and the page never names a backend.
abstract interface class NotesRepository {
  /// Returns the notes currently held by the backend.
  Future<List<Note>> fetchNotes();

  /// Stores one new note whose text is [body].
  Future<void> createNote(String body);
}
