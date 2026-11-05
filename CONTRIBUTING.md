# Contributing

## Setup

```bash
flutter pub get
dart analyze
```

## Test

```bash
cd packages/kiln_core && dart test
cd ../kiln_testing && flutter test
cd ../kiln_extension_sdk && dart test
cd ../kiln_cli && dart test
cd ../../extensions/dio && dart test
```

After changing a brick or an extension manifest:

```bash
dart run tool/bundle.dart
dart run tool/bundle.dart --check
```

## Design rules

- Application and extension code depends only on the `kiln_core` contracts.
- Extensions depend on capabilities, not on other extension ids.
- Access services through the Registry; there is no static facade or global
  registry.
- Contracts throw `Failure`; `Result<T>` is a helper for feature code.
- All installation changes go through a transaction with a journal and
  rollback.
- Never edit files owned by the user. `remove` deletes only files whose hash
  still matches.
- Extensions never import another extension; use slots.
- Extensions expose data, contracts, and wiring only. Screens, widgets, dialogs,
  and copy belong to the application.
- Code comments are in English; UI text follows the product language.

## Dependencies

Use the newest versions the toolchain can resolve. Run
`flutter pub outdated`; do not downgrade a version without a reason. The two
pins documented in `README.md` (`test` and `kiln_lints`) follow the Flutter SDK
and `custom_lint`.

## Pull requests

- Explain why the change is needed, not only what it contains.
- Include tests for new behavior or for the bug being fixed.
- Make sure `dart analyze` is clean, all suites are green, and the bundle
  check passes.
- Do not mix large refactors with behavior changes.
