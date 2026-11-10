import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:minimal/core/error/failure_presenter.dart';
import 'package:minimal/core/l10n/app_localizations_config.dart';
import 'package:minimal/core/l10n/core_copy.dart';
import 'package:minimal/extensions/l10n/failure_messages.dart';
import 'package:minimal/extensions/l10n/l10n_config.dart';
import 'package:minimal/extensions/l10n/l10n_module.dart';
import 'package:minimal/extensions/l10n/l10n_support.dart';
import 'package:minimal/extensions/l10n/locale_controller.dart';
import 'package:minimal/extensions/l10n/locale_store.dart';
import 'package:minimal/extensions/l10n/localized_core_copy.dart';
import 'package:minimal/l10n/generated/app_localizations.dart';

void main() {
  test('registers the ARB localization seam without storage', () {
    final registry = GetItRegistry();

    const L10nModule().register(registry);

    final config = registry.read<L10nConfig>();
    final controller = registry.read<LocaleController>();
    final app = registry.read<AppLocalizationsConfig>();

    expect(registry.readOrNull<LocaleStore>(), isNull);
    expect(app.supportedLocales, config.supportedLocales);
    expect(app.locale, isNull);
    expect(app.currentLocale, isNull);
    expect(app.localeListenable, same(controller.localeListenable));
    expect(app.delegates, contains(AppLocalizations.delegate));
    expect(registry.read<FailureMessages>(), isA<L10nFailureMessages>());
    expect(registry.read<L10nSupport>(), isA<L10nSupport>());
    expect(registry.read<CoreCopy>(), isA<LocalizedCoreCopy>());
  });

  test('registers LocaleStore when Storage is available', () {
    final registry = GetItRegistry();
    final storage = InMemoryStorage();
    registry.registerSingleton<Storage>(storage);

    const L10nModule().register(registry);

    expect(registry.read<LocaleStore>().storage, same(storage));
  });

  test('current locale follows the controller listenable', () async {
    final registry = GetItRegistry();
    const L10nModule().register(registry);
    final app = registry.read<AppLocalizationsConfig>();
    final controller = registry.read<LocaleController>();

    await controller.setLocale(const Locale('en'));

    expect(app.locale, isNull);
    expect(app.currentLocale, const Locale('en'));
    expect(
      registry.read<FailureMessages>().messageFor(
        const Failure(code: FailureCode.networkOffline, message: 'off'),
      ),
      lookupAppLocalizations(const Locale('en')).failureNetworkOffline,
    );
  });

  test('failure messages follow the platform locale by default', () {
    final registry = GetItRegistry();
    const L10nModule().register(registry);

    final expected = lookupAppLocalizations(
      L10nConfig.defaults.resolve(PlatformDispatcher.instance.locale),
    );

    expect(
      registry.read<FailureMessages>().messageFor(
        const Failure(code: FailureCode.networkOffline, message: 'off'),
      ),
      expected.failureNetworkOffline,
    );
  });

  test('ready restores a persisted locale', () async {
    final storage = InMemoryStorage();
    await storage.write(LocaleStore.defaultKey, 'en');
    final registry = GetItRegistry();
    registry.registerSingleton<Storage>(storage);

    const L10nModule().register(registry);
    await const L10nModule().ready(registry);

    expect(registry.read<LocaleController>().locale, const Locale('en'));
  });

  test('ready tolerates storage failures', () async {
    final registry = GetItRegistry();
    registry.registerSingleton<Storage>(_ThrowingStorage());

    const L10nModule().register(registry);
    await const L10nModule().ready(registry);

    expect(registry.read<LocaleController>().locale, isNull);
  });
}

final class _ThrowingStorage implements Storage {
  @override
  Future<void> clear() async => throw StateError('unavailable');

  @override
  Future<bool> containsKey(String key) async => throw StateError('unavailable');

  @override
  Future<void> delete(String key) async => throw StateError('unavailable');

  @override
  Future<Set<String>> keys() async => throw StateError('unavailable');

  @override
  Future<String?> read(String key) async => throw StateError('unavailable');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('unavailable');
}
