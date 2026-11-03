import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'permission_status_cache.dart';

/// Clears the permission cache when the app resumes.
final class PermissionResumeObserver implements Lifecycle {
  PermissionResumeObserver({
    required this.cache,
    this.onResumeCheck,
  });

  final PermissionStatusCache cache;
  final Future<void> Function()? onResumeCheck;
  final StreamController<LifecycleState> _changes =
      StreamController<LifecycleState>.broadcast(sync: true);
  LifecycleState _state = LifecycleState.created;

  void attach(LifecycleController controller) => controller.attach(this);

  @override
  LifecycleState get state => _state;

  @override
  Stream<LifecycleState> get changes => _changes.stream;

  @override
  Future<void> onReady() async {
    _state = LifecycleState.ready;
  }

  @override
  Future<void> onPause() async {
    _state = LifecycleState.paused;
  }

  @override
  Future<void> onResume() async {
    cache.clear();
    await onResumeCheck?.call();
    _state = LifecycleState.resumed;
  }

  @override
  Future<void> dispose() async {
    _state = LifecycleState.disposed;
    await _changes.close();
  }
}
