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
  bool _disposed = false;

  @override
  Future<List<Note>> build() async {
    _disposed = false;
    final first = Completer<List<Note>>();
    final subscription = ref.watch(watchNotesProvider).call().listen(
      (items) {
        if (!first.isCompleted) {
          first.complete(items);
          return;
        }
        _push(items);
      },
      onError: (Object error, StackTrace stackTrace) {
        final failure = _failure(error, stackTrace);
        if (!first.isCompleted) {
          first.completeError(failure, stackTrace);
          return;
        }
        _pushError(failure, stackTrace);
      },
      onDone: () {
        if (!first.isCompleted) {
          first.completeError(
            const Failure(
              code: FailureCode.unavailable,
              message: 'The notes stream ended before its first value.',
              kind: FailureKind.unavailable,
            ),
          );
        }
      },
    );
    ref.onDispose(() {
      _disposed = true;
      subscription.cancel();
    });
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
    if (_disposed) {
      return;
    }
    state = AsyncData<List<Note>>(items);
  }

  void _pushError(Failure failure, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }
    state = AsyncError<List<Note>>(failure, stackTrace);
  }

  Failure _failure(Object error, StackTrace stackTrace) =>
      error is Failure ? error : Failure.from(error, stackTrace: stackTrace);

  /// A successful mutation needs no assignment: the watched stream already
  /// carries the new list and replaces the state.
  Future<void> _report(Future<Result<Object?>> Function() action) async {
    final result = await action();
    if (_disposed) {
      return;
    }
    final failure = result.failureOrNull;
    if (failure != null) {
      state = AsyncError<List<Note>>(failure, StackTrace.current);
    }
  }
}

/// Automatic retries would keep a broken source in a loading state; the screen
/// surfaces [AsyncError] and offers an explicit Retry action instead.
final notesControllerProvider =
    AsyncNotifierProvider<NotesController, List<Note>>(
      NotesController.new,
      retry: (_, _) => null,
    );
