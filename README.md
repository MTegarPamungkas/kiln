# Kiln

Kiln generates and evolves Flutter applications through composable
extensions. A generated application depends only on the contracts in
`kiln_core`; extensions provide those contracts and communicate through
slots, never by importing each other.

## What works today

The foundation runs end-to-end: `kiln create` generates a minimal app root from
the `app_basic` brick (`--template app` adds a starter page); `kiln add` installs
an extension transactionally (pubspec dependencies, Android patches, the lockfile,
and `extensions.g.dart`); and generated projects pass `flutter analyze` and
`flutter test`. `kiln remove`, `doctor`, `list`, `graph`, `rollback`, `config`,
`cache`, `store`, `completion`, and `ext new/validate/test/pack` are available.

### Extensions (32)

| Group | Extensions |
| --- | --- |
| Auth & backends | `rest_auth`, `supabase`, `firebase`, `appwrite`, `social_login`, `biometric` |
| Data & storage | `storage`, `secure_storage`, `local_db` |
| Network | `dio`, `http_retry`, `http_cache` |
| Navigation & UI | `go_router`, `deep_link`, `theme`, `l10n`, `flavors` |
| Device | `connectivity`, `permission`, `notifications`, `image_picker`, `geolocation`, `share`, `calendar` |
| State | `bloc`, `riverpod` |
| Observability & config | `logger`, `analytics`, `crash_report`, `remote_config`, `env` |
| Tooling | `codegen` |

Extensions never render UI — they expose typed data, contracts, and wiring, and
each reports runtime platform/device/config support through `SupportRegistry`
(unsupported extensions return typed failures and do not block startup; see
[docs/extensions/support-and-devices.md](docs/extensions/support-and-devices.md)).
Each ships its manifest, docs, README, CHANGELOG, and manifest/render/analyze
tests; those that own a contract also ship a `kiln_testing` contract suite.

### Distribution

`kiln_store` (client, cache, checksum, trust, pack/publish) plus `registry/`
(index and archives) enable `kiln store install`, `kiln upgrade`, and
`kiln ext publish`. `kiln_lints` adds five custom lints
(`no_cross_extension_import`, `prefer_contract_over_impl`, `no_plugin_in_features`,
`no_edit_generated_files`, `require_failure_handling`). Examples live under
`examples/` (`minimal`, `full_stack`, `backend_swap`, `custom_extension`).

See [getting-started.md](docs/getting-started.md) and
[roadmap.md](docs/roadmap.md).

## The Gate

Every capability is reachable through one facade that returns a `Result`:
the SDK sends back success or failure plus information and never owns UI.
Build it from the registry after bootstrap:

```dart
final gate = Gate(registry);
```

One call, one result. The `permission` extension is a plain request — the app
decides what UI to show:

```dart
final result = await gate.requestPermission(PermissionKind.camera);
result.fold(
  ok: (status) => print('Granted: $status'),
  err: (failure) => print('${failure.code}: ${failure.details}'),
);
```

`Err.failure.details` carries the information the SDK sends back (status code,
server message, operation name). The same shape covers the whole SDK:

```dart
final session = await gate.signIn(email: email, password: password);
final doc = await gate.remoteRead('users', userId);
final image = await gate.pickImage(source: MediaSource.gallery);
await gate.captureEvent('checkout_started', properties: {'cart': 3});
```

On/off capabilities follow the same rule: the SDK toggles state, the app
renders it. These verbs come from each extension's `gate_<id>.dart` file:

```dart
import 'package:my_app/extensions/biometric/gate_biometric.dart';
import 'package:my_app/extensions/theme/gate_theme.dart';
import 'package:my_app/extensions/l10n/gate_l10n.dart';

final unlock = await gate.biometricUnlock();          // Result<bool>
final theme = await gate.setThemeMode(ThemeMode.dark); // Result<void>
final locale = await gate.setLocale(const Locale('id')); // Result<void>
```

Read any contract generically, or wrap a call yourself when a typed verb is
missing:

```dart
if (gate.has<Biometric>()) {
  final biometric = gate.use<Biometric>();
  final ok = await gate.call(biometric.authenticate);
}
```

`kiln_testing` registers a `Gate` automatically, so widget tests drive the
same facade through `registry.read<Gate>()`.

## Packages

| Package | Purpose |
| --- | --- |
| `kiln_core` | Contracts, failures, registry runtime, support probes, sessions, privacy |
| `kiln_extension_sdk` | Manifest, resolver, renderer, installer, migrations |
| `kiln_cli` | The `kiln` command line interface |
| `kiln_store` | Registry client, checksum verification, publishing |
| `kiln_testing` | Fakes, contract suites, and widget test harness |
| `kiln_lints` | Custom lint rules for contracts, plugins, and generated files |

## Repository layout

- `packages/` — Dart packages
- `extensions/` — extension manifests and Mason bricks
- `bricks/` — project templates used by `kiln create` and `kiln ext new`
- `schemas/` — JSON Schemas for every YAML file Kiln reads
- `docs/` — user and contributor documentation
- `tool/` — bundling, registry, drift, and release scripts

## Development

```bash
flutter pub get
dart analyze

cd packages/kiln_core && dart test
cd ../kiln_testing && flutter test
cd ../kiln_extension_sdk && dart test
cd ../kiln_cli && dart test
cd ../../extensions/dio && dart test
```

Quality checks used by CI:

```bash
dart analyze
dart run tool/bundle.dart --check             # bundled extension catalog
dart run tool/registry.dart --check           # registry index and archives
dart run tool/verify_extensions.dart --check  # per-extension golden render
dart run tool/gen_catalog_docs.dart --check   # docs/extensions/catalog.md
dart run tool/check_versions.dart --check     # version/changelog/const drift
dart run tool/check_docs.dart --check         # doc links and code fences
dart run tool/lint_extensions.dart            # manifest validation
```

`dart run tool/verify_extensions.dart --analyze [--only <id>]` renders
app_basic plus one extension into a shared fixture and runs
`flutter pub get` + `flutter analyze`.

GitHub workflows: `ci`, `extensions`, `bundles_check`, `smoke` (nightly),
`drift` (nightly), `docs`, and `release` (`v*` tags).

Creating an application from source:

```bash
dart run packages/kiln_cli/bin/kiln.dart create my_app \
  --core-path "$PWD/packages/kiln_core" \
  --with dio \
  --answer base_url=https://api.example.com \
  --yes
```

The design blueprint lives in
[docs/folder-structure.md](docs/folder-structure.md).

## Dependency policy

Every direct dependency uses a caret constraint on the newest release the
current toolchain can resolve, so a routine upgrade only needs
`flutter pub upgrade --major-versions`.

Two packages are intentionally held back because the SDK or a plugin pins
them:

- `test` stays on `1.31.1` while the Flutter SDK pins `test_api 0.7.12`;
  `test 1.33` requires `test_api 0.7.15`.
- `custom_lint_builder` 0.8.x pins `analyzer ^8`; `kiln_lints` ships on
  analyzer 8 and moves to analyzer 14 when upstream supports it.

Both constraints move forward as soon as the upstream packages allow it.
