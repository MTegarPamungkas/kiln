# minimal

A Flutter app generated with Kiln.

## Running

```bash
flutter pub get
flutter run
```

## Calling the SDK

After installing an extension, use the Gate registered by bootstrap. For
example, install `dio` with `kiln add dio` and provide your API base URL, then
inside a widget below `KilnApp`:

```dart
final gate = RegistryScope.read<Gate>(context);
final result = await gate.httpGet(Uri.parse('https://api.example.com/items'));
result.fold(
  ok: (response) => print('HTTP ${response.statusCode}'),
  err: (failure) => print(failure.message),
);
```

Import `package:kiln_core/kiln_core.dart` and this app's
`lib/app/registry_scope.dart`. The app owns the UI and error presentation.
See the [getting started guide](../../docs/getting-started.md).

## Project layout

- `lib/app/` — app skeleton, registry, and MaterialApp shell.
- `lib/core/` — theme, localization, and error handling.
- `lib/extensions/` — extension code installed via `kiln add`.
- `kiln.yaml` — project configuration and extension prompt answers.

Add extensions without editing the app skeleton:

```bash
kiln add dio
kiln add bloc
kiln doctor
```
