import 'dart:async';

/// Lifecycle position of the application or one of its components.
enum LifecycleState { created, ready, paused, resumed, disposed }

/// Receives application lifecycle callbacks.
abstract interface class Lifecycle {
  LifecycleState get state;

  Stream<LifecycleState> get changes;

  Future<void> onReady();

  Future<void> onPause();

  Future<void> onResume();

  Future<void> dispose();
}

/// Tracks lifecycle state and forwards callbacks to attached listeners.
final class LifecycleController implements Lifecycle {
  LifecycleController({
    this.listenerTimeout = const Duration(seconds: 5),
  });

  /// Maximum time allowed for each individual listener callback during
  /// [onReady], [onPause], and [onResume].
  final Duration listenerTimeout;

  final List<Lifecycle> _listeners = <Lifecycle>[];
  final List<FutureOr<void> Function()> _disposeCallbacks = [];
  Future<void>? _disposeFuture;
  final StreamController<LifecycleState> _changes =
      StreamController<LifecycleState>.broadcast(sync: true);

  LifecycleState _state = LifecycleState.created;

  @override
  LifecycleState get state => _state;

  @override
  Stream<LifecycleState> get changes => _changes.stream;

  List<Lifecycle> get listeners => List<Lifecycle>.unmodifiable(_listeners);

  void addDisposeCallback(FutureOr<void> Function() callback) {
    _checkActive();
    _disposeCallbacks.add(callback);
  }

  void attach(Lifecycle listener) {
    _checkActive();
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void detach(Lifecycle listener) {
    _listeners.remove(listener);
  }

  @override
  Future<void> onReady() async {
    _checkActive();
    await _dispatch(
      (listener) => listener.onReady(),
      LifecycleState.ready,
    );
  }

  @override
  Future<void> onPause() async {
    _checkActive();
    await _dispatch(
      (listener) => listener.onPause(),
      LifecycleState.paused,
    );
  }

  @override
  Future<void> onResume() async {
    _checkActive();
    await _dispatch(
      (listener) => listener.onResume(),
      LifecycleState.resumed,
    );
  }

  Future<void> _dispatch(
    Future<void> Function(Lifecycle listener) action,
    LifecycleState nextState,
  ) async {
    Object? firstError;
    StackTrace? firstStackTrace;
    final snapshot = List<Lifecycle>.of(_listeners);
    await Future.wait(
      snapshot.map((listener) async {
        try {
          await action(listener).timeout(listenerTimeout);
        } catch (error, stackTrace) {
          firstError ??= error;
          firstStackTrace ??= stackTrace;
        }
      }),
    );
    _set(nextState);
    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  @override
  Future<void> dispose() =>
      _disposeFuture ??= Future<void>.microtask(_dispose);

  Future<void> _dispose() async {
    Object? firstError;
    StackTrace? firstStackTrace;
    final callbacks = <FutureOr<void> Function()>[
      for (final listener in _listeners.reversed) listener.dispose,
      ..._disposeCallbacks.reversed,
    ];
    for (final callback in callbacks) {
      try {
        await callback();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    _listeners.clear();
    _disposeCallbacks.clear();
    _set(LifecycleState.disposed);
    await _changes.close();
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  void _checkActive() {
    if (_disposeFuture != null) {
      throw StateError('The lifecycle is being disposed or is already disposed.');
    }
  }

  void _set(LifecycleState state) {
    if (_disposeFuture != null && state != LifecycleState.disposed) {
      return;
    }
    if (_state == state) {
      return;
    }
    _state = state;
    if (!_changes.isClosed) {
      _changes.add(state);
    }
  }
}
