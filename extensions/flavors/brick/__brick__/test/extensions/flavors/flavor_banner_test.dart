import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/flavors/flavor_banner.dart';

Widget _app(AppFlavor flavor) {
  return MaterialApp(
    home: Scaffold(
      body: FlavorBanner(
        flavor: flavor,
        child: const Text('isi aplikasi'),
      ),
    ),
  );
}

void main() {
  testWidgets('shows DEV in development', (tester) async {
    await tester.pumpWidget(_app(AppFlavor.development));

    expect(find.text('DEV'), findsOneWidget);
    expect(find.text('isi aplikasi'), findsOneWidget);
  });

  testWidgets('shows STG in staging', (tester) async {
    await tester.pumpWidget(_app(AppFlavor.staging));

    expect(find.text('STG'), findsOneWidget);
  });

  testWidgets('hides the banner in production', (tester) async {
    await tester.pumpWidget(_app(AppFlavor.production));

    expect(find.text('DEV'), findsNothing);
    expect(find.text('STG'), findsNothing);
    expect(find.text('isi aplikasi'), findsOneWidget);
  });
}
