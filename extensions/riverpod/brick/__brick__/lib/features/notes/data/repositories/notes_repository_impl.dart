import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:{{app_name}}/features/notes/data/models/note_dto.dart';
import 'package:{{app_name}}/features/notes/domain/entities/note.dart';
import 'package:{{app_name}}/features/notes/domain/repositories/notes_repository.dart';

/// Maps the domain contract onto a [NotesLocalDatasource].
///
/// This is the only layer that converts between rows and entities, so the
/// domain stays independent of the storage format.
final class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._datasource, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  final NotesLocalDatasource _datasource;
  final Clock _clock;

  @override
  Stream<List<Note>> watch() {
    return _datasource.watchRows().map(
      (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
    );
  }

  @override
  Future<Note> add(String body) async {
    final existing = await _datasource.readRows();
    final row = NoteDto(
      id: _nextId(existing),
      body: body,
      isDone: false,
      updatedAtMs: _clock.now().millisecondsSinceEpoch,
    );
    await _datasource.writeRow(row);
    return row.toEntity();
  }

  @override
  Future<Note> toggle(String id) async {
    final row = await _require(id);
    final updated = NoteDto(
      id: row.id,
      body: row.body,
      isDone: !row.isDone,
      updatedAtMs: _clock.now().millisecondsSinceEpoch,
    );
    await _datasource.writeRow(updated);
    return updated.toEntity();
  }

  @override
  Future<void> remove(String id) async {
    await _require(id);
    await _datasource.deleteRow(id);
  }

  Future<NoteDto> _require(String id) async {
    final rows = await _datasource.readRows();
    for (final row in rows) {
      if (row.id == id) {
        return row;
      }
    }
    throw Failure(
      code: FailureCode.databaseNotFound,
      message: 'Note $id does not exist',
      kind: FailureKind.database,
      details: <String, Object?>{'noteId': id},
    );
  }

  String _nextId(List<NoteDto> rows) {
    var candidate = rows.length + 1;
    final taken = rows.map((row) => row.id).toSet();
    while (taken.contains('$candidate')) {
      candidate++;
    }
    return '$candidate';
  }
}
