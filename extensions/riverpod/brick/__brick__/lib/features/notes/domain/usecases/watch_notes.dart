import 'package:{{app_name}}/core/architecture/use_case.dart';
import 'package:{{app_name}}/features/notes/domain/entities/note.dart';
import 'package:{{app_name}}/features/notes/domain/repositories/notes_repository.dart';

/// Streams the current note list.
final class WatchNotes implements StreamUseCase<List<Note>> {
  const WatchNotes(this._repository);

  final NotesRepository _repository;

  @override
  Stream<List<Note>> call() => _repository.watch();
}
