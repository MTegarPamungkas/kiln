import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/features/notes/domain/entities/note.dart';

/// Immutable snapshot of the notes screen.
///
/// A single state object keeps the sample readable: the list streams from the
/// repository while a mutation only replaces [problem].
final class NotesState {
  const NotesState({
    this.notes = const <Note>[],
    this.isLoading = false,
    this.problem,
  });

  final List<Note> notes;
  final bool isLoading;
  final Failure? problem;

  /// Shown before the first stream value arrives.
  const NotesState.loading() : this(isLoading: true);

  bool get hasProblem => problem != null;

  /// A fresh snapshot from the repository; the stream is the source of truth.
  NotesState loaded(List<Note> notes) => NotesState(notes: notes);

  NotesState withProblem(Failure? failure) => NotesState(
    notes: notes,
    isLoading: false,
    problem: failure,
  );

  @override
  bool operator ==(Object other) =>
      other is NotesState &&
      other.isLoading == isLoading &&
      other.problem == problem &&
      _sameNotes(other.notes, notes);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(notes),
    isLoading,
    problem,
  );

  @override
  String toString() =>
      'NotesState(count: ${notes.length}, loading: $isLoading, '
      'problem: ${problem?.code.value})';
}

bool _sameNotes(List<Note> left, List<Note> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
