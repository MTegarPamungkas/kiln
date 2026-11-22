import 'package:kiln_core/kiln_core.dart';

/// [MutationLock] for the web.
///
/// A browser app runs one engine per origin, so a shared in-isolate serial lock
/// per [path] keeps concurrent callers ordered; a service worker or a second tab
/// is outside this guarantee, which is why the web implementation does not claim
/// cross-tab exclusion.
final class FileMutationLock implements MutationLock {
  FileMutationLock(this.path);

  /// Lock name; browsers have no file system, so it only keys the serial lock.
  final String path;

  static final Map<String, SerialMutationLock> _locks =
      <String, SerialMutationLock>{};

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) {
    return (_locks[path] ??= SerialMutationLock()).runExclusive(action);
  }
}
