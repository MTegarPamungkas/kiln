/// Public entry point of the notes feature.
///
/// Only this file is allowed to know all three layers at once:
/// `presentation/` depends on `domain/`, `data/` implements `domain/`, and the
/// composition below glues them together from the application [Registry].
library;

import 'package:kiln_core/kiln_core.dart';

import 'data/repositories/notes_repository_impl.dart';
import 'domain/repositories/notes_repository.dart';

export 'domain/entities/note.dart';
export 'domain/repositories/notes_repository.dart';
export 'presentation/screens/notes_page.dart';

/// Notes repository for [registry].
///
/// The backend arrives as the neutral `RemoteDatabase` contract, so this one
/// line is all the wiring the feature needs whichever extension is installed.
NotesRepository notesRepository(Registry registry) {
  return NotesRepositoryImpl(database: registry.read<RemoteDatabase>());
}
