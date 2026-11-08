import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/core/architecture/use_case.dart';
import 'package:full_stack/features/notes/domain/repositories/notes_repository.dart';

/// Deletes one note and reports a typed [Failure] when the store rejects it.
final class RemoveNote implements UseCase<String, void> {
  const RemoveNote(this._repository);

  final NotesRepository _repository;

  @override
  Future<Result<void>> call(String id) {
    return Result.guard<void>(() => _repository.remove(id));
  }
}
