/// Composition point and domain barrel of the notes feature.
///
/// Only this file may reference `data/`: `presentation/` depends on `domain/`,
/// `data/` implements `domain/`, and the wiring below glues the two together
/// from the application [Registry]. `presentation/` imports this file for the
/// domain vocabulary and [notesRepository], and the screen asks
/// [createNotesBloc] for a ready bloc, which keeps the layer rules readable
/// straight from the import list.
library;

import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:full_stack/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:full_stack/features/notes/domain/repositories/notes_repository.dart';
import 'package:full_stack/features/notes/domain/usecases/add_note.dart';
import 'package:full_stack/features/notes/domain/usecases/remove_note.dart';
import 'package:full_stack/features/notes/domain/usecases/toggle_note.dart';
import 'package:full_stack/features/notes/domain/usecases/watch_notes.dart';
import 'package:full_stack/features/notes/presentation/bloc/notes_bloc.dart';

export 'package:full_stack/features/notes/domain/entities/note.dart';
export 'package:full_stack/features/notes/domain/repositories/notes_repository.dart';
export 'package:full_stack/features/notes/domain/usecases/add_note.dart';
export 'package:full_stack/features/notes/domain/usecases/remove_note.dart';
export 'package:full_stack/features/notes/domain/usecases/toggle_note.dart';
export 'package:full_stack/features/notes/domain/usecases/watch_notes.dart';

/// Notes repository for [registry].
///
/// An application can register its own implementation, which is how a backend
/// extension replaces the in-memory sample without touching the feature.
NotesRepository notesRepository(Registry registry) {
  return registry.readOrNull<NotesRepository>() ??
      NotesRepositoryImpl(InMemoryNotesDatasource());
}

/// Builds a [NotesBloc] with its use cases wired to the repository.
NotesBloc createNotesBloc(Registry registry) {
  final repository = notesRepository(registry);
  return NotesBloc(
    watchNotes: WatchNotes(repository),
    addNote: AddNote(repository),
    toggleNote: ToggleNote(repository),
    removeNote: RemoveNote(repository),
  );
}
