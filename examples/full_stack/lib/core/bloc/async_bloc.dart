import 'package:bloc/bloc.dart';
import 'package:full_stack/core/bloc/async_state.dart';
import 'package:full_stack/core/bloc/base_bloc.dart';

/// Fetches one value for [AsyncBloc].
typedef AsyncFetcher<T> = Future<T> Function();

/// Events understood by [AsyncBloc].
sealed class AsyncBlocEvent<T> {
  const AsyncBlocEvent();
}

/// Loads the value once.
final class AsyncLoad<T> extends AsyncBlocEvent<T> {
  const AsyncLoad();
}

/// Reloads the value.
final class AsyncRefresh<T> extends AsyncBlocEvent<T> {
  const AsyncRefresh();
}

/// Repeats a failed load.
final class AsyncRetry<T> extends AsyncBlocEvent<T> {
  const AsyncRetry();
}

/// Loads one value on demand and exposes loading, data, and failure states.
final class AsyncBloc<T> extends BaseBloc<AsyncBlocEvent<T>, AsyncState<T>> {
  AsyncBloc(this._fetcher, {bool autoLoad = true}) : super(AsyncInitial<T>()) {
    on<AsyncLoad<T>>(_onLoad);
    on<AsyncRefresh<T>>(_onLoad);
    on<AsyncRetry<T>>(_onLoad);
    if (autoLoad) {
      add(AsyncLoad<T>());
    }
  }

  final AsyncFetcher<T> _fetcher;

  /// Loads the value again.
  void refresh() => add(AsyncRefresh<T>());

  /// Repeats the last load.
  void retry() => add(AsyncRetry<T>());

  Future<void> _onLoad(
    AsyncBlocEvent<T> event,
    Emitter<AsyncState<T>> emit,
  ) async {
    emit(AsyncLoading<T>());
    final result = await runGuarded<T>(_fetcher);
    result.fold(
      ok: (value) => emit(AsyncData<T>(value)),
      err: (failure) => emit(AsyncFailure<T>(failure)),
    );
  }
}
