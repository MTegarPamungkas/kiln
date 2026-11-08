import 'dart:async';

import 'package:{{app_name}}/features/notes/data/models/note_dto.dart';

/// Storage port for the notes feature.
///
/// Replace [InMemoryNotesDatasource] with a real implementation once the app
/// installs a storage or backend extension; nothing above `data/` changes.
abstract interface class NotesLocalDatasource {
  /// Emits the current snapshot immediately, then after every write.
  Stream<List<NoteDto>> watchRows();

  /// Reads every row once.
  Future<List<NoteDto>> readRows();

  /// Persists [row], replacing any row with the same id.
  Future<void> writeRow(NoteDto row);

  /// Deletes the row with [id].
  Future<void> deleteRow(String id);
}

/// Datasource used by the sample until the application owns a real store.
final class InMemoryNotesDatasource implements NotesLocalDatasource {
  InMemoryNotesDatasource({List<NoteDto> seed = sampleRows})
    : _rows = List<NoteDto>.of(seed);

  /// Two rows so a fresh app already shows content on screen.
  static const List<NoteDto> sampleRows = <NoteDto>[
    NoteDto(id: '1', body: 'Read the folder guide', isDone: false),
    NoteDto(id: '2', body: 'Wire a real datasource', isDone: false),
  ];

  final List<NoteDto> _rows;
  final StreamController<List<NoteDto>> _changes =
      StreamController<List<NoteDto>>.broadcast();

  @override
  Stream<List<NoteDto>> watchRows() async* {
    yield List<NoteDto>.unmodifiable(_rows);
    yield* _changes.stream;
  }

  @override
  Future<List<NoteDto>> readRows() async {
    return List<NoteDto>.unmodifiable(_rows);
  }

  @override
  Future<void> writeRow(NoteDto row) async {
    final index = _rows.indexWhere((item) => item.id == row.id);
    if (index < 0) {
      _rows.add(row);
    } else {
      _rows[index] = row;
    }
    _emit();
  }

  @override
  Future<void> deleteRow(String id) async {
    _rows.removeWhere((item) => item.id == id);
    _emit();
  }

  /// Releases the change stream; call this from a disposal hook or a test.
  Future<void> dispose() async {
    await _changes.close();
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(List<NoteDto>.unmodifiable(_rows));
    }
  }
}
