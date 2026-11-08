import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/architecture/use_case.dart';
import 'package:{{app_name}}/features/notes/domain/entities/note.dart';
import 'package:{{app_name}}/features/notes/domain/repositories/notes_repository.dart';

/// Creates one note and turns an empty draft into a validation [Err].
final class AddNote implements UseCase<String, Note> {
  const AddNote(this._repository);

  final NotesRepository _repository;

  @override
  Future<Result<Note>> call(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return Err<Note>(
        const Failure(
          code: FailureCode.validationInvalidInput,
          message: 'Note body must not be empty',
          kind: FailureKind.validation,
        ),
      );
    }
    return Result.guard<Note>(() => _repository.add(trimmed));
  }
}
