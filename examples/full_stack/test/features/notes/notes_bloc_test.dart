import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:full_stack/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:full_stack/features/notes/domain/repositories/notes_repository.dart';
import 'package:full_stack/features/notes/domain/usecases/add_note.dart';
import 'package:full_stack/features/notes/domain/usecases/remove_note.dart';
import 'package:full_stack/features/notes/domain/usecases/toggle_note.dart';
import 'package:full_stack/features/notes/domain/usecases/watch_notes.dart';
import 'package:full_stack/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:full_stack/features/notes/presentation/bloc/notes_event.dart';

NotesBloc _buildBloc(NotesRepository repository) {
  return NotesBloc(
    watchNotes: WatchNotes(repository),
    addNote: AddNote(repository),
    toggleNote: ToggleNote(repository),
    removeNote: RemoveNote(repository),
  );
}

Future<void> _until(bool Function() condition) async {
  var attempts = 0;
  while (!condition() && attempts < 100) {
    attempts++;
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('streams the seeded rows then stops loading', () async {
    final bloc = _buildBloc(NotesRepositoryImpl(InMemoryNotesDatasource()));

    await _until(() => !bloc.state.isLoading);

    expect(bloc.state.notes.map((note) => note.body), <String>[
      'Read the folder guide',
      'Wire a real datasource',
    ]);
    await bloc.close();
  });

  test('NoteAdded appends through the repository', () async {
    final bloc = _buildBloc(NotesRepositoryImpl(InMemoryNotesDatasource()));
    await _until(() => !bloc.state.isLoading);

    bloc.add(const NoteAdded('Third note'));
    await _until(() => bloc.state.notes.length == 3);

    expect(bloc.state.notes.last.body, 'Third note');
    expect(bloc.state.hasProblem, isFalse);
    await bloc.close();
  });

  test('an empty draft surfaces a validation problem', () async {
    final bloc = _buildBloc(NotesRepositoryImpl(InMemoryNotesDatasource()));
    await _until(() => !bloc.state.isLoading);

    bloc.add(const NoteAdded('   '));
    await _until(() => bloc.state.hasProblem);

    expect(bloc.state.problem?.kind, FailureKind.validation);
    await bloc.close();
  });

  test('NoteToggled flips the flag', () async {
    final bloc = _buildBloc(NotesRepositoryImpl(InMemoryNotesDatasource()));
    await _until(() => !bloc.state.isLoading);

    bloc.add(const NoteToggled('1'));
    await _until(() => bloc.state.notes.first.isDone);

    expect(bloc.state.notes.first.isDone, isTrue);
    await bloc.close();
  });

  test(
    'removing an unknown id keeps the list and reports the failure',
    () async {
      final bloc = _buildBloc(NotesRepositoryImpl(InMemoryNotesDatasource()));
      await _until(() => !bloc.state.isLoading);

      bloc.add(const NoteRemoved('missing'));
      await _until(() => bloc.state.hasProblem);

      expect(bloc.state.problem?.code, FailureCode.databaseNotFound);
      expect(bloc.state.notes, hasLength(2));

      bloc.add(const NoteRemoved('1'));
      await _until(() => bloc.state.notes.length == 1);
      expect(bloc.state.notes.single.body, 'Wire a real datasource');
      await bloc.close();
    },
  );
}
