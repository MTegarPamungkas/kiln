/// Mutual exclusion for one mutation group (a queue, a migration, an import).
///
/// The contract deliberately says nothing about the mechanism: a process-wide
/// serial queue and a file lock both satisfy it. Applications that run more than
/// one isolate, engine or process against the same data must supply an
/// implementation that excludes them (see the `local_db` extension's
/// `FileMutationLock`); the core `SerialMutationLock` only serializes callers in
/// one isolate.
///
/// `runExclusive` must release the lock when the action completes or throws, and
/// must not swallow the action's error.
abstract interface class MutationLock {
  /// Runs [action] while holding the lock, serialized with other callers.
  Future<T> runExclusive<T>(Future<T> Function() action);
}
