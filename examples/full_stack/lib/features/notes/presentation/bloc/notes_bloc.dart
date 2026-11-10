import 'package:bloc/bloc.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/core/bloc/base_bloc.dart';
import 'package:full_stack/features/notes/domain/entities/note.dart';
import 'package:full_stack/features/notes/domain/usecases/add_note.dart';
import 'package:full_stack/features/notes/domain/usecases/remove_note.dart';
import 'package:full_stack/features/notes/domain/usecases/toggle_note.dart';
import 'package:full_stack/features/notes/domain/usecases/watch_notes.dart';
import 'package:full_stack/features/notes/presentation/bloc/notes_event.dart';
import 'package:full_stack/features/notes/presentation/bloc/notes_state.dart';

/// Drives the notes screen from domain use cases.
///
/// The bloc never touches a repository, a datasource, or a plugin: it knows
/// the use cases and the state it emits.
final class NotesBloc extends BaseBloc<NotesEvent, NotesState> {
  NotesBloc({
    required this.watchNotes,
    required this.addNote,
    required this.toggleNote,
    required this.removeNote,
  }) : super(const NotesState.loading()) {
    on<NotesStarted>(_onStarted);
    on<NoteAdded>(_onAdded);
    on<NoteToggled>(_onToggled);
    on<NoteRemoved>(_onRemoved);
    add(const NotesStarted());
  }

  final WatchNotes watchNotes;
  final AddNote addNote;
  final ToggleNote toggleNote;
  final RemoveNote removeNote;

  Future<void> _onStarted(NotesStarted event, Emitter<NotesState> emitter) {
    return emitter.forEach<List<Note>>(
      watchNotes(),
      onData: (notes) => state.loaded(notes),
      onError: (error, stackTrace) =>
          state.withProblem(Failure.from(error, stackTrace: stackTrace)),
    );
  }

  Future<void> _onAdded(NoteAdded event, Emitter<NotesState> emitter) async {
    reportResult(await addNote(event.body), emitter, state.withProblem);
  }

  Future<void> _onToggled(
    NoteToggled event,
    Emitter<NotesState> emitter,
  ) async {
    reportResult(await toggleNote(event.noteId), emitter, state.withProblem);
  }

  Future<void> _onRemoved(
    NoteRemoved event,
    Emitter<NotesState> emitter,
  ) async {
    reportResult(await removeNote(event.noteId), emitter, state.withProblem);
  }
}
