import 'package:{{app_name}}/features/notes/domain/entities/note.dart';

/// A note row exactly as the data source stores it.
///
/// Keeping the map shape here means the domain entity never learns how notes
/// are persisted, so swapping storage cannot ripple upward.
final class NoteDto {
  const NoteDto({
    required this.id,
    required this.body,
    this.isDone = false,
    this.updatedAtMs,
  });

  factory NoteDto.fromNote(Note note) {
    return NoteDto(
      id: note.id,
      body: note.body,
      isDone: note.isDone,
      updatedAtMs: note.updatedAt?.millisecondsSinceEpoch,
    );
  }

  factory NoteDto.fromMap(Map<String, Object?> map) {
    final rawId = map['id'];
    final rawBody = map['body'];
    final rawDone = map['is_done'];
    final rawUpdatedAt = map['updated_at'];
    return NoteDto(
      id: rawId is String ? rawId : '$rawId',
      body: rawBody is String ? rawBody : '$rawBody',
      isDone: rawDone == true || rawDone == 1,
      updatedAtMs: rawUpdatedAt is int ? rawUpdatedAt : null,
    );
  }

  final String id;
  final String body;
  final bool isDone;
  final int? updatedAtMs;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'body': body,
    'is_done': isDone,
    'updated_at': updatedAtMs,
  };

  Note toEntity() {
    final updated = updatedAtMs;
    return Note(
      id: id,
      body: body,
      isDone: isDone,
      updatedAt: updated == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updated),
    );
  }
}
