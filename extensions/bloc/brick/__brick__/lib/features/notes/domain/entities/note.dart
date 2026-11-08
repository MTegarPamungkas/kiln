/// One note owned by the notes feature.
///
/// The entity is framework-free: it holds only what the domain means by a
/// note, never a storage or transport shape.
final class Note {
  const Note({
    required this.id,
    required this.body,
    this.isDone = false,
    this.updatedAt,
  });

  final String id;
  final String body;
  final bool isDone;
  final DateTime? updatedAt;

  Note copyWith({String? body, bool? isDone, DateTime? updatedAt}) {
    return Note(
      id: id,
      body: body ?? this.body,
      isDone: isDone ?? this.isDone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.body == body &&
      other.isDone == isDone &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, body, isDone, updatedAt);

  @override
  String toString() => 'Note($id, $body, done: $isDone)';
}
