# Format, plural, dan pesan

## Placeholder

Deklarasikan placeholder di ARB:

```json
{
  "helloName": "Hello, {name}!",
  "@helloName": {
    "placeholders": {
      "name": { "type": "String" }
    }
  }
}
```

gen-l10n menghasilkan method bertipe:

```dart
Text(l10n.helloName('Ana'));
```

## Plural

```json
{
  "itemsCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemsCount": {
    "placeholders": {
      "count": { "type": "int" }
    }
  }
}
```

Pemakaian:

```dart
Text(l10n.itemsCount(0)); // No items
Text(l10n.itemsCount(1)); // 1 item
Text(l10n.itemsCount(3)); // 3 items
```

Aturan plural mengikuti locale (`intl.Intl.pluralLogic`). Indonesia memakai
satu bentuk `other`; Inggris memakai `one`/`other` dan boleh menambah `=0`.

## Tanggal

```dart
final formatters = LocaleFormatters(locale: const Locale('id'));

formatters.formatDate(DateTime(2024, 1, 15)); // 15 Januari 2024
formatters.formatMediumDate(DateTime(2024, 1, 15));
formatters.formatDateTime(DateTime(2024, 1, 15, 9, 30));
```

Data tanggal `intl` diinisialisasi oleh `L10nModule.ready`. Di unit test yang
tidak menjalankan modul, panggil `LocaleFormatters.initialize()` lebih dulu.

## Angka dan mata uang

```dart
formatters.formatNumber(1234.5); // 1.234,5
formatters.formatNumber(1234.567, decimalDigits: 2); // 1.234,57
formatters.formatPercent(0.12); // 12%
formatters.formatCompactNumber(1200); // 1,2 rb
formatters.formatCurrency(1250000, decimalDigits: 0); // Rp1.250.000
formatters.formatCurrency(1234.5, currencyCode: 'USD'); // $1,234.50
```

Simbol mata uang mengikuti locale. Untuk data keuangan, tentukan
`currencyCode` secara eksplisit agar tidak bergantung pada locale perangkat.

## Pesan kegagalan

`L10nFailureMessages` mengelompokkan `FailureCode` menjadi getter ARB yang
ramah. Contoh: `network.offline` menjadi `failureNetworkOffline`, sedangkan
`storage.read_failed` dan `storage.write_failed` berbagi `failureStorage`.
Kode yang tidak dikenal memakai `failureUnexpected`, bukan pesan teknis dari
exception.
