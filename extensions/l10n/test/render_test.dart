import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('l10n brick renders the expected files', () async {
    final harness = ExtensionTestHarness(
      extensionRoot: Directory.current,
    );

    final files = await harness.render(project: const {'name': 'l10n_app'});
    final paths = files.map((file) => file.relativePath).toList();

    expect(
      paths,
      containsAll(<String>[
        'l10n.yaml',
        'lib/l10n/app_en.arb',
        'lib/l10n/app_id.arb',
        'lib/extensions/l10n/l10n_module.dart',
        'lib/extensions/l10n/l10n_config.dart',
        'lib/extensions/l10n/locale_resolution.dart',
        'lib/extensions/l10n/locale_controller.dart',
        'lib/extensions/l10n/locale_store.dart',
        'lib/extensions/l10n/localized_core_copy.dart',
        'lib/extensions/l10n/locale_formatters.dart',
        'lib/extensions/l10n/failure_messages.dart',
        'lib/extensions/l10n/widgets/language_switcher.dart',
        'test/extensions/l10n/l10n_test.dart',
        'test/extensions/l10n/l10n_module_test.dart',
        'test/extensions/l10n/l10n_config_test.dart',
        'test/extensions/l10n/locale_resolution_test.dart',
        'test/extensions/l10n/locale_controller_test.dart',
        'test/extensions/l10n/locale_store_test.dart',
        'test/extensions/l10n/locale_formatters_test.dart',
        'test/extensions/l10n/failure_messages_test.dart',
        'test/extensions/l10n/language_switcher_test.dart',
        'test/extensions/l10n/l10n_coverage_test.dart',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('l10n_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);

    expect(source, contains("Locale('id')"));
    expect(source, contains("Locale('en')"));
    expect(source, contains("defaultFallback = Locale('id')"));
    expect(source, isNot(contains('{{')));

    final golden = File(
      p.join(
        Directory.current.path,
        'test',
        'goldens',
        'rendered',
        'lib',
        'extensions',
        'l10n',
        'l10n_config.dart.golden',
      ),
    );
    if (Platform.environment['UPDATE_GOLDENS'] == '1') {
      await golden.parent.create(recursive: true);
      await golden.writeAsString(source);
    }
    expect(source, golden.readAsStringSync());
  });

  test('l10n brick renders the selected locales', () async {
    final harness = ExtensionTestHarness(
      extensionRoot: Directory.current,
    );

    final files = await harness.render(
      answers: const <String, Object?>{
        'locales': <String>['en'],
        'fallback_locale': 'en',
      },
      project: const {'name': 'l10n_app'},
    );
    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('l10n_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);

    expect(source, contains("Locale('en')"));
    expect(source, isNot(contains("Locale('id'),")));
    expect(source, contains("defaultFallback = Locale('en')"));
  });
}
