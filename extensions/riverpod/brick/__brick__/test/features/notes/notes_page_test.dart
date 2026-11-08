import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/core/riverpod/kiln_providers.dart';
import 'package:{{app_name}}/features/notes/presentation/screens/notes_page.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var attempt = 0; attempt < 12; attempt++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _pumpApp(WidgetTester tester, Registry registry) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [registryProvider.overrideWithValue(registry)],
      child: const MaterialApp(home: NotesPage()),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('shows the seeded rows', (tester) async {
    await _pumpApp(tester, createTestRegistry());

    expect(find.text('Read the folder guide'), findsOneWidget);
    expect(find.text('Wire a real datasource'), findsOneWidget);
  });

  testWidgets('the composer adds a note and clears itself', (tester) async {
    await _pumpApp(tester, createTestRegistry());

    await tester.enterText(
      find.byKey(const Key('notes-composer')),
      'Typed from the widget test',
    );
    await tester.tap(find.byKey(const Key('notes-add')));
    await _settle(tester);

    expect(find.text('Typed from the widget test'), findsOneWidget);
    final composer = tester.widget<TextField>(
      find.byKey(const Key('notes-composer')),
    );
    expect(composer.controller?.text, isEmpty);
  });

  testWidgets('an empty draft shows the failure copy and a retry', (tester) async {
    await _pumpApp(tester, createTestRegistry());

    await tester.tap(find.byKey(const Key('notes-add')));
    await _settle(tester);

    expect(find.text('Note body must not be empty'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('retry brings the list back', (tester) async {
    await _pumpApp(tester, createTestRegistry());

    await tester.tap(find.byKey(const Key('notes-add')));
    await _settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await _settle(tester);

    expect(find.text('Read the folder guide'), findsOneWidget);
  });

  testWidgets('tapping a row toggles without throwing', (tester) async {
    await _pumpApp(tester, createTestRegistry());

    await tester.tap(find.text('Read the folder guide'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Read the folder guide'), findsOneWidget);
  });
}
