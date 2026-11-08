import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/features/notes/domain/entities/note.dart';
import 'package:{{app_name}}/features/notes/presentation/providers/notes_providers.dart';

/// Reads the note list and exposes the mutations the screen offers.
///
/// Like its Bloc sibling, this class only knows use cases: the repository and
/// the datasource stay behind the provider layer. One subscription carries both
/// the first snapshot and every later change, so the stream stays the single
/// source of truth.
final class NotesController extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final first = Completer<List<Note>>();
    final subscription = ref.watch(watchNotesProvider).call().listen((items) {
      if (!first.isCompleted) {
        first.complete(items);
        return;
      }
      _push(items);
    });
    ref.onDispose(subscription.cancel);
    return first.future;
  }

  /// Adds [body]; a rejected draft becomes an [AsyncError].
  Future<void> add(String body) =>
      _report(() => ref.read(addNoteProvider).call(body));

  /// Flips the done flag of [id].
  Future<void> toggle(String id) =>
      _report(() => ref.read(toggleNoteProvider).call(id));

  /// Deletes [id].
  Future<void> remove(String id) =>
      _report(() => ref.read(removeNoteProvider).call(id));

  void _push(List<Note> items) {
    state = AsyncData<List<Note>>(items);
  }

  /// A successful mutation needs no assignment: the watched stream already
  /// carries the new list and replaces the state.
  Future<void> _report(Future<Result<Object?>> Function() action) async {
    final result = await action();
    final failure = result.failureOrNull;
    if (failure != null) {
      state = AsyncError<List<Note>>(failure, StackTrace.current);
    }
  }
}

final notesControllerProvider =
    AsyncNotifierProvider<NotesController, List<Note>>(NotesController.new);
