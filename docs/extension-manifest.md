# Extension manifest

Every extension has an `extension.yaml` at the root of its folder. The machine
schema lives in `schemas/extension.schema.json`. Additional validation is done
by `ManifestValidator`.

## Example

```yaml
id: http_retry
name: HTTP retry
version: 0.1.0
description: Retries temporary HTTP failures with backoff.
category: network
tier: official
provides: [http_client, http_pipeline] # capabilities provided
requires: [http_client, http_pipeline] # capabilities required
optional_requires: [storage]           # used when available
slots:
  - name: http.interceptors
    item: HttpMiddleware
contributes:
  - slot: http.interceptors
    item: HttpMiddleware
    priority: 20
    when: [http_pipeline]
prompts:
  - name: base_url
    type: url
    required: true
  - name: connect_timeout
    type: int
    default: 15
    min: 1
    max: 120
dependencies:
  http_retry: ^0.0.1
dev_dependencies: {}
platforms: [android, ios, web]
android:
  permissions: [android.permission.INTERNET]
  url_schemes: [kiln]
  url_scheme_prompt: scheme
  app_links:
    hosts: [kiln.dev]
    path_prefixes: [/profile]
  allow_backup: false
  min_sdk: 24
  compile_sdk: 37
  receivers:
    - name: com.example.BootReceiver
      exported: false
      actions: [android.intent.action.BOOT_COMPLETED]
ios:
  plist:
    NSFaceIDUsageDescription: Unlock the app
  podfile_permissions: [camera]
  associated_domains: [kiln.dev]
  entitlements:
    com.apple.developer.applesignin: [Default]
  url_schemes: [kiln]
  url_scheme_prompt: scheme
macos:
  entitlements:
    com.apple.security.network.client: true
  url_schemes: [kiln]
  url_scheme_prompt: scheme
web:
  index_html: true
conditional:
  - when:
      exact_alarms: true
    android:
      permissions: [android.permission.SCHEDULE_EXACT_ALARM]
manual_steps:
  - id: flutterfire_configure
    description: Run flutterfire configure
compatibility:
  kiln: ">=0.1.0 <0.2.0"
  dart: ">=3.9.0"
  flutter: ">=3.35.0"
```

## Important fields

- `provides` and `requires` use capability names, not extension ids.
- `exclusive: true` means only one extension in the same category may be
  installed.
- `slots` opens attachment points; `contributes` attaches to slots opened by
  other extensions. The item must match the slot type.
- `when` keeps a contribution active only while all listed capabilities are
  available.
- `prompts` are typed as `string`, `url`, `int`, `bool`, `enum`, `secret`, or
  `multi`. A `secret` prompt is not stored in `kiln.yaml`; its value is stored
  in `env/*.json`.
- Native patches are applied only when the platform folder exists in the
  project.
- `conditional` applies a native block only when all prompt answers in `when`
  match; lists are compared element by element. A scalar expected value matches
  when a multi-select answer contains it, so `kinds: camera` can add the camera
  native setup.
- `android.compile_sdk` raises the project value only when it is lower; the
  patch is recorded and reverted with the extension.
- `manual_steps` are tracked by `kiln doctor`.

## Runtime support

`platforms` is a build-time filter. Device and service readiness is not declared
in the manifest; the module reports it from `KilnModule.support()` and
`KilnBootstrap` records the result in `SupportRegistry`. See
[extensions/support-and-devices.md](extensions/support-and-devices.md).

## Validation

```bash
kiln ext validate extensions/http_retry
```

The validator rejects non-snake_case ids, invalid semver, duplicate
capabilities, prompts without enum/multi options, `requires` on the extension's
own capability, duplicate slots, and invalid or duplicated Android permissions,
URL schemes (optionally driven by a prompt through `url_scheme_prompt`), App
Link hosts/path prefixes, and receivers.
