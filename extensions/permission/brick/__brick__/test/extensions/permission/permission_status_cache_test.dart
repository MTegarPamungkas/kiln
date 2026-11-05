import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/permission_status_cache.dart';

void main() {
  test('stores, replaces, and clears statuses', () {
    final cache = PermissionStatusCache()
      ..set(PermissionKind.camera, PermissionStatus.denied)
      ..set(PermissionKind.photos, PermissionStatus.granted);

    expect(cache.get(PermissionKind.camera), PermissionStatus.denied);
    expect(cache.get(PermissionKind.photos), PermissionStatus.granted);

    cache.clear();
    expect(cache.get(PermissionKind.camera), isNull);
    expect(cache.get(PermissionKind.photos), isNull);
  });
}
