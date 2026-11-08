import 'package:{{app_name}}/features/notes/domain/entities/note.dart';

/// Contract the presentation layer depends on.
///
/// The implementation lives in `data/`; nothing outside this feature needs to
/// know where notes are stored.
abstract interface class NotesRepository {
  /// Emits the current list on subscribe, then after every change.
  Stream<List<Note>> watch();

  /// Adds one note and returns it.
  Future<Note> add(String body);

  /// Flips the done flag of one note and returns it.
  Future<Note> toggle(String id);

  /// Removes one note.
  Future<void> remove(String id);
}
