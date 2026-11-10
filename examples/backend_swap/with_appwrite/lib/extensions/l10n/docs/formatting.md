# Formatting, plurals, and messages

## Placeholders

Declare placeholders in the ARB:

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

gen-l10n produces a typed method:

```dart
Text(l10n.helloName('Ana'));
```

## Plurals

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

Usage:

```dart
Text(l10n.itemsCount(0)); // No items
Text(l10n.itemsCount(1)); // 1 item
Text(l10n.itemsCount(3)); // 3 items
```

Plural rules follow the locale (`intl.Intl.pluralLogic`). Indonesian uses a
single `other` form; English uses `one`/`other` and may add `=0`.

## Dates

```dart
final formatters = LocaleFormatters(locale: const Locale('id'));

formatters.formatDate(DateTime(2024, 1, 15)); // 15 Januari 2024
formatters.formatMediumDate(DateTime(2024, 1, 15));
formatters.formatDateTime(DateTime(2024, 1, 15, 9, 30));
```

The `intl` date data is initialized by `L10nModule.ready`. In unit tests that do
not run the module, call `LocaleFormatters.initialize()` first.

## Numbers and currency

```dart
formatters.formatNumber(1234.5); // 1.234,5
formatters.formatNumber(1234.567, decimalDigits: 2); // 1.234,57
formatters.formatPercent(0.12); // 12%
formatters.formatCompactNumber(1200); // 1,2 rb
formatters.formatCurrency(1250000, decimalDigits: 0); // Rp1.250.000
formatters.formatCurrency(1234.5, currencyCode: 'USD'); // $1,234.50
```

Currency symbols follow the locale. For financial data, set `currencyCode`
explicitly so it does not depend on the device locale.

## Failure messages

`L10nFailureMessages` groups `FailureCode` values into friendly ARB getters. For
example, `network.offline` becomes `failureNetworkOffline`, while
`storage.read_failed` and `storage.write_failed` share `failureStorage`.
Unrecognized codes use `failureUnexpected`, not the technical message from the
exception.
