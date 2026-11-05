import 'package:full_stack/core/bloc/async_state.dart';
import 'package:full_stack/core/bloc/base_cubit.dart';

typedef AsyncFetcher<T> = Future<T> Function();

/// Loads one value and exposes loading, data, and failure states.
final class AsyncCubit<T> extends BaseCubit<AsyncState<T>> {
  AsyncCubit(this._fetcher) : super(AsyncInitial<T>());

  final AsyncFetcher<T> _fetcher;

  Future<void> load() async {
    safeEmit(AsyncLoading<T>());
    final result = await runGuarded<T>(_fetcher);
    result.fold(
      ok: (value) => safeEmit(AsyncData<T>(value)),
      err: (failure) => safeEmit(AsyncFailure<T>(failure)),
    );
  }

  Future<void> refresh() => load();

  Future<void> retry() => load();
}
