import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{app_name}}/core/riverpod/kiln_providers.dart';
import 'package:{{app_name}}/features/notes/feature.dart';

/// Notes repository, resolved through the feature's composition point.
///
/// `presentation/` never builds a repository and never imports `data/`:
/// [notesRepository] decides which implementation the application gets, so
/// swapping the sample for a backend extension touches `feature.dart` only.
final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => notesRepository(ref.watch(registryProvider)),
);

/// Streams the note list after every change.
final watchNotesProvider = Provider<WatchNotes>(
  (ref) => WatchNotes(ref.watch(notesRepositoryProvider)),
);

/// Creates one note.
final addNoteProvider = Provider<AddNote>(
  (ref) => AddNote(ref.watch(notesRepositoryProvider)),
);

/// Flips the done flag of one note.
final toggleNoteProvider = Provider<ToggleNote>(
  (ref) => ToggleNote(ref.watch(notesRepositoryProvider)),
);

/// Deletes one note.
final removeNoteProvider = Provider<RemoveNote>(
  (ref) => RemoveNote(ref.watch(notesRepositoryProvider)),
);
