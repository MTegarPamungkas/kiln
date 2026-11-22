import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../kiln_exception.dart';
import 'root_path.dart';

/// Holds an OS lock until release or process termination.
///
/// Retaining the file prevents races between locks on different inodes.
/// Only descendants of [run] can acquire this lock reentrantly.
final class ProjectLock {
  ProjectLock._(this._key, this._handle, this._owner);

  static final Map<String, ProjectLock> _held = {};
  static final Object _zoneKey = Object();
  final String _key;
  final RandomAccessFile? _handle;
  final ProjectLock? _owner;
  bool _released = false;

  static Future<ProjectLock> acquire(
    Directory projectRoot, {
    // Kept for source compatibility. OS locks have no age-based expiry.
    Duration staleAfter = const Duration(minutes: 10),
  }) async {
    final root = Directory(projectRoot.resolveSymbolicLinksSync());
    final canonical = p.normalize(root.path);
    final key = Platform.isWindows ? canonical.toLowerCase() : canonical;
    final held = _held[key];
    if (held != null) {
      final owners = Zone.current[_zoneKey] as Map<String, ProjectLock>?;
      if (identical(owners?[key], held)) {
        return ProjectLock._(key, null, held);
      }
      throw _busy();
    }

    final paths = RootPath(root);
    Directory(paths.resolve('.kiln')).createSync(recursive: true);
    final file = File(paths.resolve('.kiln/project.lock'));
    final handle = file.openSync(mode: FileMode.append);
    try {
      handle.lockSync(FileLock.exclusive);
    } on FileSystemException {
      handle.closeSync();
      throw _busy();
    }
    try {
      handle
        ..truncateSync(0)
        ..setPositionSync(0)
        ..writeStringSync(
          jsonEncode({
            'pid': pid,
            'startedAt': DateTime.now().toUtc().toIso8601String(),
          }),
        )
        ..flushSync();
      final lock = ProjectLock._(key, handle, null);
      _held[key] = lock;
      return lock;
    } catch (_) {
      handle.unlockSync();
      handle.closeSync();
      rethrow;
    }
  }

  static KilnException _busy() => const KilnException(
    'Another Kiln operation is modifying this project.',
    code: 'project.busy',
    suggestion: 'Wait for it to finish. Terminated processes release locks automatically.',
  );

  void release() {
    if (_released) return;
    _released = true;
    if (_owner != null) return;
    _held.remove(_key);
    try {
      _handle!.unlockSync();
    } finally {
      _handle!.closeSync();
    }
  }

  Future<T> run<T>(Future<T> Function() action) async {
    if (_released) throw StateError('The project lock has been released.');
    final owner = _owner ?? this;
    final owners = {
      ...?(Zone.current[_zoneKey] as Map<String, ProjectLock>?),
      _key: owner,
    };
    try {
      return await runZoned(action, zoneValues: {_zoneKey: owners});
    } finally {
      release();
    }
  }
}
