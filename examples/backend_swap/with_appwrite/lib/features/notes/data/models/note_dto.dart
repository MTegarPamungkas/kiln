import '../../domain/entities/note.dart';

/// A backend row, mapped to and from a [Note].
///
/// Both installed backends normalise the row id into an `id` key and the apps
/// keep their note text in a `title` column, so one mapper serves Appwrite and
/// Supabase. Reading is tolerant on purpose: a collection that has not got the
/// optional `done` or `updated_at` columns yet still maps cleanly.
final class NoteDto {
  const NoteDto(this.row);

  /// Column that holds the note text in every variant.
  static const String bodyColumn = 'title';

  /// Column that holds the done flag, when the collection defines it.
  static const String doneColumn = 'done';

  /// Column that holds the last update timestamp, when it is defined.
  static const String updatedAtColumn = 'updated_at';

  final Map<String, Object?> row;

  Note toEntity() {
    return Note(
      id: row['id']?.toString() ?? '',
      body: row[bodyColumn]?.toString() ?? 'Untitled',
      isDone: row[doneColumn] == true,
      updatedAt: DateTime.tryParse(row[updatedAtColumn]?.toString() ?? ''),
    );
  }
}
