import 'dart:io';

import 'package:kiln_core/kiln_core.dart';

/// [MutationLock] over an advisory OS file lock.
///
/// The action runs while this handle holds an exclusive lock on [path], so a
/// second isolate, engine or process that opens the same path waits instead of
/// mutating the same queue or database concurrently. The wait is a blocking
/// operating-system lock: a competing caller parks until the holder releases,
/// it does not fail or spin. The operating system releases the lock when the
/// process exits, so a crash cannot leave the data permanently blocked.
///
/// POSIX `fcntl` locks are owned by the process, so two lock objects opened in
/// the same process do not necessarily exclude each other; keep the in-isolate
/// serialization (see [SerialMutationLock]) as well when the app can run
/// concurrent tasks in one isolate. On Windows the lock is owned by the file
/// handle, so acquiring the same [path] twice in one process waits for itself;
/// do not nest a `runExclusive` on the same path in that process.
///
/// A writer that does not take the lock is not excluded, and the lock file
/// itself is left behind (empty and harmless).
final class FileMutationLock implements MutationLock {
  FileMutationLock(this.path);

  /// Lock file path; the file itself is created on first use.
  final String path;

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final handle = await file.open(mode: FileMode.write);
    // `FileLock.exclusive` is non-blocking on Windows and on POSIX `fcntl`
    // (it throws when another holder exists). The blocking variant is what
    // makes a second process wait for the current mutation to finish.
    try {
      await handle.lock(FileLock.blockingExclusive);
      return await action();
    } finally {
      try {
        await handle.unlock();
      } on Object {
        // Closing the handle also releases the lock.
      }
      await handle.close();
    }
  }
}
