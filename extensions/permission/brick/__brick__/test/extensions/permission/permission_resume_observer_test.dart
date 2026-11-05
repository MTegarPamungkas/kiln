import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/permission_resume_observer.dart';
import 'package:{{app_name}}/extensions/permission/permission_status_cache.dart';

void main() {
  test('resume clears the cache and runs the check', () async {
    final cache = PermissionStatusCache()
      ..set(PermissionKind.camera, PermissionStatus.granted);
    var checks = 0;
    final observer = PermissionResumeObserver(
      cache: cache,
      onResumeCheck: () async => checks++,
    );

    await observer.onResume();

    expect(cache.get(PermissionKind.camera), isNull);
    expect(checks, 1);
    expect(observer.state, LifecycleState.resumed);
    await observer.dispose();
  });
}
