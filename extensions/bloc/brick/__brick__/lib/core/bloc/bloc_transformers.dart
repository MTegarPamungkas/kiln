import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

/// Runs an event after no new event arrives for [duration].
EventTransformer<T> debounceEvents<T>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
}

/// Runs the first event in each [duration] window.
EventTransformer<T> throttleEvents<T>(Duration duration) {
  return (events, mapper) => events.throttleTime(duration).flatMap(mapper);
}

/// Drops events while the previous one is still running.
EventTransformer<T> droppableEvents<T>() => droppable<T>();

/// Restarts the handler when a new event arrives.
EventTransformer<T> restartableEvents<T>() => restartable<T>();
