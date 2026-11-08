/// Composition point and domain barrel of the notes feature.
///
/// Only this file may reference `data/`: `presentation/` depends on `domain/`,
/// `data/` implements `domain/`, and the wiring below glues the two together
/// from the application [Registry]. `presentation/` imports this file to get
/// the domain vocabulary and [notesRepository], which keeps the layer rules
/// readable straight from the import list.
library;

import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:{{app_name}}/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:{{app_name}}/features/notes/domain/repositories/notes_repository.dart';

export 'package:{{app_name}}/features/notes/domain/entities/note.dart';
export 'package:{{app_name}}/features/notes/domain/repositories/notes_repository.dart';
export 'package:{{app_name}}/features/notes/domain/usecases/add_note.dart';
export 'package:{{app_name}}/features/notes/domain/usecases/remove_note.dart';
export 'package:{{app_name}}/features/notes/domain/usecases/toggle_note.dart';
export 'package:{{app_name}}/features/notes/domain/usecases/watch_notes.dart';

/// Notes repository for [registry].
///
/// An application can register its own implementation, which is how a backend
/// extension replaces the in-memory sample without touching the feature.
NotesRepository notesRepository(Registry registry) {
  return registry.readOrNull<NotesRepository>() ??
      NotesRepositoryImpl(InMemoryNotesDatasource());
}
