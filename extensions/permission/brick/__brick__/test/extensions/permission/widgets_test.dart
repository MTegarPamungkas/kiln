import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/permission/widgets/permission_dialogs.dart';
import 'package:{{app_name}}/extensions/permission/widgets/permission_gate.dart';

import 'test_support.dart';

void main() {
  testWidgets('PermissionGate shows child only when granted', (tester) async {
    final gateway = FakePermissionGateway(
      statuses: {PermissionKind.camera: PermissionStatus.granted},
    );
    final permissions = createDevicePermissions(gateway: gateway);

    await tester.pumpWidget(
      MaterialApp(
        home: PermissionGate(
          permissions: permissions,
          kind: PermissionKind.camera,
          fallback: (_) => const Text('denied'),
          child: const Text('camera ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('camera ready'), findsOneWidget);
    expect(find.text('denied'), findsNothing);
  });

  testWidgets('PermissionGate shows fallback when denied', (tester) async {
    final gateway = FakePermissionGateway(
      statuses: {PermissionKind.camera: PermissionStatus.denied},
    );
    final permissions = createDevicePermissions(gateway: gateway);

    await tester.pumpWidget(
      MaterialApp(
        home: PermissionGate(
          permissions: permissions,
          kind: PermissionKind.camera,
          fallback: (_) => const Text('denied'),
          child: const Text('camera ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('denied'), findsOneWidget);
  });

  testWidgets('rationale dialog returns the chosen action', (tester) async {
    late Future<bool> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              result = PermissionRationaleDialog.show(
                context,
                title: 'Kamera',
                message: 'Butuh kamera',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Butuh kamera'), findsOneWidget);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });
}
