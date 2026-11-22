import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:{{app_name}}/features/notes/data/models/note_dto.dart';
import 'package:{{app_name}}/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:{{app_name}}/features/notes/domain/entities/note.dart';
import 'package:{{app_name}}/features/notes/domain/repositories/notes_repository.dart';
import 'package:{{app_name}}/features/notes/presentation/providers/notes_controller.dart';
import 'package:{{app_name}}/features/notes/presentation/providers/notes_providers.dart';

Future<void> _idle() => Future<void>.delayed(Duration.zero);

final class _ControlledRepository implements NotesRepository {
  _ControlledRepository(this.events, {this.onAdd});

  final StreamController<List<Note>> events;
  final Future<Note> Function(String body)? onAdd;

  @override
  Stream<List<Note>> watch() => events.stream;

  @override
  Future<Note> add(String body) {
    final handler = onAdd;
    if (handler != null) {
      return handler(body);
    }
    return Future<Note>.value(Note(id: 'x', body: body));
  }

  @override
  Future<Note> toggle(String id) async => Note(id: id, body: id, isDone: true);

  @override
  Future<void> remove(String id) async {}
}

ProviderContainer _container({NotesRepository? repository}) {
  return ProviderContainer(
    overrides: [
      notesRepositoryProvider.overrideWithValue(
        repository ?? NotesRepositoryImpl(InMemoryNotesDatasource()),
      ),
    ],
  );
}

List<Note> _notes(ProviderContainer container) =>
    container.read(notesControllerProvider).requireValue;

NotesController _controller(ProviderContainer container) =>
    container.read(notesControllerProvider.notifier);

void main() {
  test('builds from the seeded rows', () async {
    final container = _container();
    addTearDown(container.dispose);

    final notes = await container.read(notesControllerProvider.future);

    expect(
      notes.map((note) => note.body),
      containsAll(<String>[
        'Read the folder guide',
        'Wire a real datasource',
      ]),
    );
  });

  test('add streams the new list back in', () async {
    final container = _container();
    addTearDown(container.dispose);
    await container.read(notesControllerProvider.future);

    await _controller(container).add('Written here');
    await _idle();

    expect(_notes(container), hasLength(3));
    expect(_notes(container).last.body, 'Written here');
  });

  test('an empty draft becomes an AsyncError carrying the Failure', () async {
    final container = _container();
    addTearDown(container.dispose);
    await container.read(notesControllerProvider.future);

    await _controller(container).add('   ');
    await _idle();

    final state = container.read(notesControllerProvider);
    expect(state.hasError, isTrue);
    final error = state.error;
    expect(error, isA<Failure>());
    expect((error as Failure).kind, FailureKind.validation);
  });

  test('toggle flips the done flag through the stream', () async {
    final container = _container();
    addTearDown(container.dispose);
    await container.read(notesControllerProvider.future);

    await _controller(container).toggle('1');
    await _idle();

    expect(_notes(container).first.isDone, isTrue);
  });

  test('an unknown id fails, then a known id removes', () async {
    final container = _container();
    addTearDown(container.dispose);
    await container.read(notesControllerProvider.future);

    await _controller(container).remove('missing');
    await _idle();
    final error = container.read(notesControllerProvider).error;
    expect((error as Failure).code, FailureCode.databaseNotFound);

    await _controller(container).remove('1');
    await _idle();

    expect(_notes(container).map((note) => note.id), <String>['2']);
  });

  test('invalidate after a failure restores the list', () async {
    final container = _container();
    addTearDown(container.dispose);
    await container.read(notesControllerProvider.future);

    await _controller(container).add('   ');
    await _idle();
    container.invalidate(notesControllerProvider);
    await _idle();

    expect(_notes(container), hasLength(2));
  });

  test('a stream error before the first value becomes an AsyncError', () async {
    final events = StreamController<List<Note>>();
    final container = _container(
      repository: _ControlledRepository(events),
    );
    addTearDown(() async {
      await events.close();
      container.dispose();
    });

    final future = container.read(notesControllerProvider.future);
    events.addError(StateError('stream failed'));

    await expectLater(future, throwsA(isA<Failure>()));
    expect(container.read(notesControllerProvider).hasError, isTrue);
  });

  test('a completed empty stream becomes an AsyncError', () async {
    final events = StreamController<List<Note>>();
    final container = _container(
      repository: _ControlledRepository(events),
    );
    addTearDown(() async {
      await events.close();
      container.dispose();
    });

    final future = container.read(notesControllerProvider.future);
    await events.close();

    await expectLater(
      future,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.unavailable,
        ),
      ),
    );
    expect(container.read(notesControllerProvider).hasError, isTrue);
  });

  test('a later stream error is surfaced and the stream keeps updating', () async {
    final events = StreamController<List<Note>>();
    final container = _container(
      repository: _ControlledRepository(events),
    );
    addTearDown(() async {
      await events.close();
      container.dispose();
    });

    final future = container.read(notesControllerProvider.future);
    events.add(const <Note>[Note(id: '1', body: 'one')]);
    await future;

    events.addError(StateError('later failure'));
    await _idle();
    expect(container.read(notesControllerProvider).hasError, isTrue);

    events.add(const <Note>[Note(id: '2', body: 'two')]);
    await _idle();
    expect(_notes(container).single.id, '2');
  });

  test('a pending mutation does not write state after disposal', () async {
    final events = StreamController<List<Note>>();
    final addGate = Completer<Note>();
    final container = _container(
      repository: _ControlledRepository(
        events,
        onAdd: (_) => addGate.future,
      ),
    );
    final future = container.read(notesControllerProvider.future);
    events.add(const <Note>[]);
    await future;
    final controller = _controller(container);

    final mutation = controller.add('pending');
    container.dispose();
    addGate.complete(const Note(id: 'x', body: 'pending'));

    await mutation;
    await events.close();
  });

  test('a registered repository replaces the sample store', () async {
    final repository = NotesRepositoryImpl(
      InMemoryNotesDatasource(
        seed: const <NoteDto>[
          NoteDto(id: 'only', body: 'From the override', isDone: true),
        ],
      ),
    );
    final container = _container(repository: repository);
    addTearDown(container.dispose);

    final notes = await container.read(notesControllerProvider.future);

    expect(notes.single.id, 'only');
  });
}
