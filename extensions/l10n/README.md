# l10n

Localization extension for Kiln with ARB file translation sources and
`flutter gen-l10n`.

- `AppLocalizations` is generated from `lib/l10n/app_<locale>.arb`.
- `L10nModule` registers `AppLocalizationsConfig`, `L10nConfig`,
  `LocaleController`, the generated delegates, and `FailureMessages`.
- `LocaleController` stores the locale choice; `null` means follow the device
  locale. The choice is persisted through `Storage` when the `storage` extension is installed.
- The application renders its own language picker from `gate.supportedLocales`.
- `LocaleFormatters` provides date, number, and currency formats.

## Install

`kiln create` always installs `l10n`. For projects created before this
rule, add it manually:

```bash
kiln add l10n
flutter pub get
kiln doctor
```

The installer adds `flutter: generate: true` to the pubspec. During `pub get`,
Flutter runs gen-l10n from `l10n.yaml` and the `lib/l10n` folder.

## Usage

```dart
final l10n = AppLocalizations.of(context);

Text(l10n.readyTitle);
Text(l10n.helloName('Ana'));
Text(l10n.itemsCount(3));
```

Changing the language from an application-owned control:

```dart
final controller = registry.read<LocaleController>();

await controller.setLocale(const Locale('id'));
```

Failure messages are applied automatically when `FailurePresenter.fromRegistry` is used:

```dart
final presenter = FailurePresenter.fromRegistry(registry);
showSnackBar(SnackBar(content: Text(presenter.present(failure))));
```

Details are in [docs/l10n.md](docs/l10n.md),
[docs/adding-a-language.md](docs/adding-a-language.md), and
[docs/formatting.md](docs/formatting.md).

## Gate

```dart
import 'package:my_app/extensions/l10n/gate_l10n.dart';

final current = gate.locale;                  // Locale?
final options = gate.supportedLocales;        // List<Locale>
await gate.setLocale(const Locale('id'));     // Result<void>
await gate.followSystemLocale();              // Result<void>
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
