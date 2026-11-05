import 'package:kiln_core/kiln_core.dart';

/// State for an asynchronous load.
sealed class AsyncState<T> {
  const AsyncState();
}

final class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();
}

final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

final class AsyncData<T> extends AsyncState<T> {
  const AsyncData(this.value);

  final T value;
}

final class AsyncFailure<T> extends AsyncState<T> {
  const AsyncFailure(this.failure);

  final Failure failure;
}
