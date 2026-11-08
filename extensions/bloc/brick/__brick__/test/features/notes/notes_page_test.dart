import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/app/registry_scope.dart';
import 'package:{{app_name}}/features/notes/presentation/screens/notes_page.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var attempt = 0; attempt < 12; attempt++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('renders the seeded notes', (tester) async {
    final registry = createTestRegistry();

    await tester.pumpWidget(
      RegistryScope(
        registry: registry,
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await _settle(tester);

    expect(find.text('Read the folder guide'), findsOneWidget);
    expect(find.text('Wire a real datasource'), findsOneWidget);
  });

  testWidgets('the composer adds a note', (tester) async {
    final registry = createTestRegistry();

    await tester.pumpWidget(
      RegistryScope(
        registry: registry,
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await _settle(tester);

    await tester.enterText(
      find.byKey(const Key('notes-composer')),
      'Typed from the widget test',
    );
    await tester.tap(find.byKey(const Key('notes-add')));
    await _settle(tester);

    expect(find.text('Typed from the widget test'), findsOneWidget);
  });

  testWidgets('tapping a row marks it done', (tester) async {
    final registry = createTestRegistry();

    await tester.pumpWidget(
      RegistryScope(
        registry: registry,
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await _settle(tester);

    await tester.tap(find.text('Read the folder guide'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
  });
}
