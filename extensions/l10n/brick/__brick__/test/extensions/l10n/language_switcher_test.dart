import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/l10n/l10n_config.dart';
import 'package:{{app_name}}/extensions/l10n/locale_controller.dart';
import 'package:{{app_name}}/extensions/l10n/widgets/language_switcher.dart';
import 'package:{{app_name}}/l10n/generated/app_localizations.dart';

void main() {
  const config = L10nConfig.defaults;
  const switcherKey = Key('kiln-language-switcher');

  Future<LocaleController> pumpSwitcher(
    WidgetTester tester, {
    LanguageSwitcherStyle style = LanguageSwitcherStyle.dropdown,
  }) async {
    final controller = LocaleController(config: config);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LanguageSwitcher(
              controller: controller,
              config: config,
              style: style,
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('lists supported languages and follows the system by default', (
    tester,
  ) async {
    final controller = await pumpSwitcher(tester);
    final dropdown = tester.widget<DropdownButton<String>>(
      find.byKey(switcherKey),
    );

    expect(controller.locale, isNull);
    expect(dropdown.items, hasLength(config.supportedLocales.length + 1));
    final labels = dropdown.items!
        .map((item) => (item.child as Text).data)
        .whereType<String>();
    expect(
      labels,
      containsAll(<String>['Ikuti sistem', 'Bahasa Indonesia', 'English']),
    );
    expect(dropdown.value, isNot('en'));
  });

  testWidgets('selecting a language updates the controller', (tester) async {
    final controller = await pumpSwitcher(tester);

    await tester.tap(find.byKey(switcherKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byKey(switcherKey),
    );
    expect(controller.locale, const Locale('en'));
    expect(dropdown.value, 'en');
  });

  testWidgets('selecting follow system clears the choice', (tester) async {
    final controller = await pumpSwitcher(tester);

    await tester.tap(find.byKey(switcherKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(controller.locale, const Locale('en'));

    await tester.tap(find.byKey(switcherKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ikuti sistem').last);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byKey(switcherKey),
    );
    expect(controller.locale, isNull);
    expect(dropdown.value, isNot('en'));
  });

  testWidgets('segmented style also updates the controller', (tester) async {
    final controller = await pumpSwitcher(
      tester,
      style: LanguageSwitcherStyle.segmented,
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(controller.locale, const Locale('en'));
  });

  testWidgets('reflects a locale changed outside the widget', (tester) async {
    final controller = await pumpSwitcher(tester);

    await controller.setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byKey(switcherKey),
    );
    expect(dropdown.value, 'en');
  });
}
