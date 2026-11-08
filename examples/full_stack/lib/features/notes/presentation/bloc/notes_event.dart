/// User intents handled by `NotesBloc`.
sealed class NotesEvent {
  const NotesEvent();
}

/// Subscribes to the note stream.
final class NotesStarted extends NotesEvent {
  const NotesStarted();
}

/// Creates a note from the composer text.
final class NoteAdded extends NotesEvent {
  const NoteAdded(this.body);

  final String body;
}

/// Flips the done flag of one note.
final class NoteToggled extends NotesEvent {
  const NoteToggled(this.noteId);

  final String noteId;
}

/// Deletes one note.
final class NoteRemoved extends NotesEvent {
  const NoteRemoved(this.noteId);

  final String noteId;
}
