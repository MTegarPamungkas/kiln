# l10n

Extension lokalisasi untuk Kiln dengan sumber terjemahan file ARB dan
`flutter gen-l10n`.

- `AppLocalizations` dihasilkan dari `lib/l10n/app_<locale>.arb`.
- `L10nModule` mendaftarkan `AppLocalizationsConfig`, `L10nConfig`,
  `LocaleController`, delegate hasil generate, dan `FailureMessages`.
- `LocaleController` menyimpan pilihan locale; `null` berarti mengikuti locale
  perangkat. Pilihan disimpan lewat `Storage` bila extension `storage` terpasang.
- `LanguageSwitcher` menampilkan bahasa dari `L10nConfig.supportedLocales`.
- `LocaleFormatters` menyediakan format tanggal, angka, dan mata uang.

## Pasang

`kiln create` selalu memasang `l10n`. Untuk proyek yang dibuat sebelum aturan
ini, tambahkan manual:

```bash
kiln add l10n
flutter pub get
kiln doctor
```

Installer menambahkan `flutter: generate: true` ke pubspec. Saat `pub get`,
Flutter menjalankan gen-l10n dari `l10n.yaml` dan folder `lib/l10n`.

## Pakai

```dart
final l10n = AppLocalizations.of(context);

Text(l10n.readyTitle);
Text(l10n.helloName('Ana'));
Text(l10n.itemsCount(3));
```

Mengubah bahasa dari UI:

```dart
final controller = registry.read<LocaleController>();

LanguageSwitcher(controller: controller);
```

Pesan kegagalan otomatis terpakai bila `FailurePresenter.fromRegistry` dipakai:

```dart
final presenter = FailurePresenter.fromRegistry(registry);
showSnackBar(SnackBar(content: Text(presenter.present(failure))));
```

Rincian ada di [docs/l10n.md](docs/l10n.md),
[docs/adding-a-language.md](docs/adding-a-language.md), dan
[docs/formatting.md](docs/formatting.md).
