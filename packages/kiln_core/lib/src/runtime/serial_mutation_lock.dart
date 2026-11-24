import 'dart:async';

import '../contracts/mutation_lock.dart';

/// [MutationLock] that serializes callers in this isolate, in arrival order.
///
/// Every caller waits for the previous action to finish, including when it
/// throws. This is the right default for a single-isolate application and for
/// tests; it does not exclude another isolate, engine or process.
///
/// This lock is **not re-entrant**: calling [runExclusive] from inside an
/// action already holding the same lock will deadlock forever.
final class SerialMutationLock implements MutationLock {
  Future<void> _tail = Future<void>.value();

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) {
    final previous = _tail;
    final released = Completer<void>();
    _tail = released.future;
    return previous.then((_) => action()).whenComplete(released.complete);
  }
}
