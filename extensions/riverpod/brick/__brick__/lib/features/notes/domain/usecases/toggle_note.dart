import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/architecture/use_case.dart';
import 'package:{{app_name}}/features/notes/domain/entities/note.dart';
import 'package:{{app_name}}/features/notes/domain/repositories/notes_repository.dart';

/// Flips the done flag of one note.
final class ToggleNote implements UseCase<String, Note> {
  const ToggleNote(this._repository);

  final NotesRepository _repository;

  @override
  Future<Result<Note>> call(String id) {
    return Result.guard<Note>(() => _repository.toggle(id));
  }
}
