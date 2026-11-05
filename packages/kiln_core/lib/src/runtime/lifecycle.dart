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
  final List<Lifecycle> _listeners = <Lifecycle>[];
  final StreamController<LifecycleState> _changes =
      StreamController<LifecycleState>.broadcast(sync: true);

  LifecycleState _state = LifecycleState.created;

  @override
  LifecycleState get state => _state;

  @override
  Stream<LifecycleState> get changes => _changes.stream;

  List<Lifecycle> get listeners => List<Lifecycle>.unmodifiable(_listeners);

  void attach(Lifecycle listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void detach(Lifecycle listener) {
    _listeners.remove(listener);
  }

  @override
  Future<void> onReady() async {
    for (final listener in List<Lifecycle>.of(_listeners)) {
      await listener.onReady();
    }
    _set(LifecycleState.ready);
  }

  @override
  Future<void> onPause() async {
    for (final listener in List<Lifecycle>.of(_listeners)) {
      await listener.onPause();
    }
    _set(LifecycleState.paused);
  }

  @override
  Future<void> onResume() async {
    for (final listener in List<Lifecycle>.of(_listeners)) {
      await listener.onResume();
    }
    _set(LifecycleState.resumed);
  }

  @override
  Future<void> dispose() async {
    for (final listener in List<Lifecycle>.of(_listeners.reversed)) {
      await listener.dispose();
    }
    _listeners.clear();
    _set(LifecycleState.disposed);
    await _changes.close();
  }

  void _set(LifecycleState state) {
    if (_state == state) {
      return;
    }
    _state = state;
    if (!_changes.isClosed) {
      _changes.add(state);
    }
  }
}
