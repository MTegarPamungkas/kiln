import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/permission_config.dart';
import 'package:{{app_name}}/extensions/permission/permission_kind_guard.dart';

void main() {
  test('accepts enabled kinds and rejects others', () {
    const guard = PermissionKindGuard(
      PermissionConfig(activeKinds: {PermissionKind.camera}),
    );

    expect(() => guard.ensure(PermissionKind.camera), returnsNormally);
    expect(
      () => guard.ensure(PermissionKind.microphone),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.configurationInvalid,
        ),
      ),
    );
  });
}
