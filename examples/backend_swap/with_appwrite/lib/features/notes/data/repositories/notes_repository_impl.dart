import 'package:kiln_core/kiln_core.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../models/note_dto.dart';

/// [NotesRepository] on top of the backend-neutral [RemoteDatabase] contract.
///
/// This is the only place the feature touches a transport shape, and it never
/// mentions Appwrite or Supabase: whichever extension is installed, the
/// registry hands out a [RemoteDatabase] and the rows map into [Note]s here.
/// Swapping the backend means changing no line of this file.
final class NotesRepositoryImpl implements NotesRepository {
  const NotesRepositoryImpl({
    required this.database,
    this.collection = 'notes',
  });

  final RemoteDatabase database;
  final String collection;

  @override
  Future<List<Note>> fetchNotes() async {
    final rows = await database.query(collection);
    return rows.map((row) => NoteDto(row).toEntity()).toList(growable: false);
  }

  @override
  Future<void> createNote(String body) async {
    await database.create(collection, <String, Object?>{
      NoteDto.bodyColumn: body,
    });
  }
}
