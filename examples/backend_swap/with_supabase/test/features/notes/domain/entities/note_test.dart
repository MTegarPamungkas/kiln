import 'package:flutter_test/flutter_test.dart';
import 'package:with_supabase/features/notes/domain/entities/note.dart';

void main() {
  final seed = Note(
    id: 'n1',
    body: 'Buy milk',
    updatedAt: DateTime.parse('2026-01-02T03:04:05.000Z'),
  );

  group('Note', () {
    test('defaults an unstored note to not done', () {
      expect(const Note(id: 'n1', body: 'Buy milk').isDone, isFalse);
      expect(const Note(id: 'n1', body: 'Buy milk').updatedAt, isNull);
    });

    test('copyWith keeps the identity and replaces what is given', () {
      final copy = seed.copyWith(isDone: true);

      expect(copy.id, seed.id);
      expect(copy.body, seed.body);
      expect(copy.updatedAt, seed.updatedAt);
      expect(copy.isDone, isTrue);
    });

    test('is a value object', () {
      expect(seed, seed.copyWith());
      expect(seed.hashCode, seed.copyWith().hashCode);
      expect(seed, isNot(seed.copyWith(body: 'Buy bread')));
      expect(seed, isNot(seed.copyWith(isDone: true)));
      expect(seed, isNot(const Note(id: 'other', body: 'Buy milk')));
    });

    test('copyWith cannot clear a nullable field', () {
      // `updatedAt ?? this.updatedAt` keeps the previous value, so passing
      // null is a no-op. Build a new Note instead of trying to clear it.
      expect(seed.copyWith(updatedAt: null), seed);
    });

    test('describes itself for logs', () {
      expect(seed.toString(), contains('Buy milk'));
    });
  });
}
