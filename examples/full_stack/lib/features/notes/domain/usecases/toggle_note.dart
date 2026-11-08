import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/core/architecture/use_case.dart';
import 'package:full_stack/features/notes/domain/entities/note.dart';
import 'package:full_stack/features/notes/domain/repositories/notes_repository.dart';

/// Flips the done flag of one note.
final class ToggleNote implements UseCase<String, Note> {
  const ToggleNote(this._repository);

  final NotesRepository _repository;

  @override
  Future<Result<Note>> call(String id) {
    return Result.guard<Note>(() => _repository.toggle(id));
  }
}
