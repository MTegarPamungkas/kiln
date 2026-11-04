import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/l10n/gate_l10n.dart';
import 'package:{{app_name}}/extensions/l10n/l10n_config.dart';
import 'package:{{app_name}}/extensions/l10n/locale_controller.dart';

void main() {
  test('gate switches and follows the locale in one call', () async {
    final registry = GetItRegistry()
      ..registerSingleton<LocaleController>(
        LocaleController(
          config: const L10nConfig(
            supportedLocales: [Locale('id'), Locale('en')],
            fallbackLocale: Locale('id'),
          ),
        ),
      );
    final gate = Gate(registry);

    expect(gate.locale, isNull);

    final result = await gate.setLocale(Locale('id'));
    expect(result, isA<Ok<void>>());
    expect(gate.locale, Locale('id'));

    final follow = await gate.followSystemLocale();
    expect(follow, isA<Ok<void>>());
    expect(gate.locale, isNull);
  });
}
