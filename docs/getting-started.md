# Getting started with Kiln

## Prerequisites

- Flutter 3.47 or newer
- Dart 3.13 or newer
- Git (optional for generated projects)

## Repo setup

```bash
git clone <repo-kiln>
cd kiln
flutter pub get
dart analyze
```

For SDK development and the complete test commands, see the
[repository development guide](../README.md#development).

## Creating an app

Run the CLI from source. `--core-path` makes the project use `kiln_core` and
`kiln_testing` from the workspace instead of pub.dev:

```bash
dart run packages/kiln_cli/bin/kiln.dart create my_app \
  --org com.example \
  --core-path "$PWD/packages/kiln_core" \
  --with dio \
  --answer base_url=https://api.example.com \
  --yes
```

`kiln_core` is not published on pub.dev, so a project needs a source. Inside
the workspace the CLI uses the local checkout, so edits to `kiln_core` show up
immediately. Everything else resolves the SDK from the public repository:

```bash
kiln create my_app --yes          # kiln_core from a pinned Kiln commit
kiln create my_app \
  --core-git https://github.com/you/kiln.git \
  --core-ref v0.1.0 \
  --yes
```

`--core-git` writes both `kiln_core` and `kiln_testing` as git dependencies and
pins `dependency_overrides` to the same revision, because pub refuses to resolve
one package from two sources. Pass `--core-ref` (branch, tag, or commit) to pin
the revision; without it pub follows the default branch, and `kiln doctor`
reports that as a warning so a project can be pinned before it is shipped.
`--core-path` and `--core-git` cannot be combined.

`kiln create` generates the minimal template by default: bootstrap, registry
scope, MaterialApp seams, and one application-owned `HomePage`. It does not
generate a starter shell, feature navigation, or auth flow. Use
`--template app` when you want the starter page and demo shell:

```bash
kiln create my_app --template app
```

`kiln create` always installs the `l10n` extension, so all shell text comes
from ARB files and the template keeps no hardcoded application strings. `l10n`
also adds `flutter: generate: true` automatically and runs gen-l10n on
`pub get`.

Without `--with`, the project can still be created and other extensions added
afterwards:

```bash
cd my_app
dart run ../packages/kiln_cli/bin/kiln.dart add dio \
  --answer base_url=https://api.example.com
```

Other commands:

```bash
kiln list
kiln doctor
kiln graph
kiln remove dio --yes
```

## Call a service and handle the result

Bootstrap makes `Gate` available automatically. In a widget below the generated
`KilnApp`, import the app's `registry_scope.dart` and `kiln_core`, then read it:

```dart
final gate = RegistryScope.read<Gate>(context);
final result = await gate.httpGet(Uri.parse('https://api.example.com/items'));
result.fold(
  ok: (response) => print('HTTP ${response.statusCode}: ${response.body}'),
  err: (failure) => print('${failure.code}: ${failure.message}'),
);
```

This example needs the `dio` extension installed above. Replace the URL with
your endpoint. Inside a widget under `lib/features/home/presentation/screens/`,
the imports are:

```dart
import 'package:kiln_core/kiln_core.dart';
import '../../../../app/registry_scope.dart';
```

Outside widgets, pass the Gate to your feature or service. After bootstrap,
retrieve it with `registry.read<Gate>()`; do not introduce a global instance.

Typed verbs such as `httpGet` and `signIn` return `Ok(value)` or `Err(failure)`.
A missing service also returns `Err`. HTTP responses retain their status code,
including 4xx and 5xx; decide how your UI handles them. Direct getters such as
`gate.http` can throw and are intended for advanced use.

For operations without a verb, keep the service lookup inside `call`:

```dart
// Requires the local_db extension.
final notes = await gate.call(() => gate.localDb.query('notes'));
```

The application decides what to display, navigate to, or retry. See the
[Gate reference](reference/gate.md) for available operations. You can start
building features with this flow; capability and slot details are covered
separately in [architecture](architecture.md).

## Editing and updating your app

Run `kiln setup` to list the configuration status of installed extensions.
Use `kiln setup <extension>` to review one, or `kiln setup --all` to review all
installed extensions. See [Configure installed extensions](guides/configure-extensions.md)
for previews, typed answers, secret handling, and batch rollback.

For an Appwrite backend, continue with
[Set up Appwrite](guides/setup-appwrite.md): install → configure → doctor → sign in.

Build your screens and business logic in `lib/features/`. Before editing
installed extension code, read the
[file ownership guide](concepts/lockfile-and-ownership.md#editing-installed-code).
Preview upgrades with `kiln upgrade --dry-run`, and use `kiln doctor` to report
modified files and wiring issues.

## Generated project structure

```text
my_app/
├─ lib/
│  ├─ main.dart
│  ├─ app/            # KilnApp, RegistryScope, AppShell seams, error screen
│  ├─ features/home/  # application-owned starting feature (minimal template)
│  │  └─ presentation/screens/  # home_page.dart, the layer folders a feature grows into
│  ├─ core/           # architecture contracts, theme, l10n seams, global error handler
│  ├─ extensions/     # extension code + extensions.g.dart
│  └─ ...
├─ test/
├─ ARCHITECTURE.md    # folder map, the dependency rule, and the recipe for a new feature
├─ kiln.yaml
├─ kiln.lock.yaml
└─ .kiln/             # journal and backups, ignored by Git
```

The starter template (`--template app`) also includes `app_home.dart` and the
starter page. The minimal template passes its own `HomePage` to `KilnApp`.

`ARCHITECTURE.md` at the project root carries the folder map, the dependency
rule, and the recipe for adding a feature. Every feature follows it, including
the `notes` sample a state extension installs under `lib/features/notes/`.

`lib/extensions/extensions.g.dart` is the only application file owned by Kiln.
Do not edit it by hand; `kiln doctor --fix` keeps it in sync.

## Runtime support

Bootstrap probes every installed extension after registration. Results are
available without app-side platform checks:

```dart
final support = registry.read<SupportRegistry>();

final biometric = support['biometric'];
if (biometric?.isSupported ?? false) {
  // show the biometric action
} else {
  // show biometric?.message and fall back
}
```

Unsupported extensions are reported as `unsupportedPlatform`,
`unsupportedDevice`, `permissionDenied`, `notConfigured`, or `unavailable`.
Their `ready()` hook is skipped, and calls return typed failures such as
`support.unsupported_device` or `PermissionStatus.unsupported`. The full
coverage table is in
[extensions/support-and-devices.md](extensions/support-and-devices.md).

## Writing an extension

```bash
kiln ext new hello --name "Hello extension" --provides hello
kiln ext validate extensions/hello
kiln ext test extensions/hello
kiln ext pack extensions/hello
```

Read [extensions/writing-an-extension.md](extensions/writing-an-extension.md)
and [extension-manifest.md](extension-manifest.md).

## Bundled catalog

The bundled catalog provides:

- `bloc` and `riverpod` for state management (exclusive).
- `dio` for the HTTP client and pipeline.
- `http_retry` and `http_cache` for HTTP resilience and caching.
- `storage`, `secure_storage`, and `local_db` for key-value, secrets, and
  offline-first databases.
- `connectivity`, `permission`, `notifications`, and `image_picker` for network
  status, permissions, local notifications, and image picking.
- `rest_auth`, `appwrite`, `firebase`, and `supabase` for authentication,
  remote databases, and file storage; `social_login` and `biometric` for social
  sign-in, app lock, and protected storage.
- `go_router`, `deep_link`, `theme`, and `l10n` for navigation, incoming links,
  theming, and ARB-based localization.
- `geolocation`, `share`, and `calendar` for device position, the native share
  sheet, and calendar events.
- `env`, `flavors`, `logger`, and `analytics` for build-time configuration,
  per-flavor entry points, logging, and consent-based analytics.
- `crash_report` (Sentry error reporting behind a consent gate and PII redaction),
  `remote_config` (vendor-neutral feature flags), and `codegen` (`json_serializable`
  + `freezed` model generation).

```bash
kiln create state_app --state bloc
kiln add http_retry
kiln add http_cache
kiln add connectivity permission notifications image_picker
```

## Registry

```bash
kiln config --registry="$(pwd)/registry"
kiln store search logger
kiln store install logger --yes
kiln upgrade --yes
```

Publish a single extension to a local registry:

```bash
kiln ext publish extensions/logger --registry="$(pwd)/registry"
```

`tool/registry.dart` rebuilds `registry/index.json` and every archive from the
`extensions/` folder.

## Current limitations

- Publishing directly to an HTTP registry is not active yet; publish to a local
  folder instead.
