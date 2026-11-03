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

All tests:

```bash
cd packages/kiln_core && dart test
cd ../kiln_testing && flutter test
cd ../kiln_extension_sdk && dart test
cd ../kiln_cli && dart test
cd ../../extensions/dio && dart test
```

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

## Generated project structure

```text
my_app/
├─ lib/
│  ├─ main.dart
│  ├─ app/            # KilnApp, RegistryScope, AppShell, error screen
│  ├─ core/           # theme, l10n, global error handler
│  ├─ extensions/     # extension code + extensions.g.dart
│  └─ ...
├─ test/
├─ kiln.yaml
├─ kiln.lock.yaml
└─ .kiln/             # journal and backups, ignored by Git
```

`lib/extensions/extensions.g.dart` is the only application file owned by Kiln.
Do not edit it by hand; `kiln doctor --fix` keeps it in sync.

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

Phase 2 currently provides:

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
- `env`, `flavors`, `logger`, and `analytics` for build-time configuration,
  per-flavor entry points, logging, and consent-based analytics.

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
- `kiln_lints` is waiting for `custom_lint` to support analyzer 14.
