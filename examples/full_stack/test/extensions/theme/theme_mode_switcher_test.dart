import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/theme/theme_mode_controller.dart';
import 'package:full_stack/extensions/theme/widgets/theme_mode_switcher.dart';

void main() {
  testWidgets('shows System, Light, and Dark segments', (tester) async {
    final controller = ThemeModeController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(child: ThemeModeSwitcher(controller: controller)),
        ),
      ),
    );

    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    expect(find.text('Sistem'), findsOneWidget);
    expect(find.text('Terang'), findsOneWidget);
    expect(find.text('Gelap'), findsOneWidget);
  });

  testWidgets('selecting a segment changes the mode', (tester) async {
    final controller = ThemeModeController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(child: ThemeModeSwitcher(controller: controller)),
        ),
      ),
    );

    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.dark);

    await tester.tap(find.text('Terang'));
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.light);

    await tester.tap(find.text('Sistem'));
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.system);
  });

  testWidgets('reflects a mode changed outside the widget', (tester) async {
    final controller = ThemeModeController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(child: ThemeModeSwitcher(controller: controller)),
        ),
      ),
    );

    await controller.setMode(ThemeMode.dark);
    await tester.pump();

    final button = tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );
    expect(button.selected, <ThemeMode>{ThemeMode.dark});
  });
}
