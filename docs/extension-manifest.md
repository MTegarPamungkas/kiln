# Manifest extension

Setiap extension memiliki `extension.yaml` di root foldernya. Schema mesin:
`schemas/extension.schema.json`. Validator tambahan:
`ManifestValidator`.

## Contoh

```yaml
id: http_retry
name: HTTP retry
version: 0.1.0
description: Retries temporary HTTP failures with backoff.
category: network
tier: official
provides: [http_client, http_pipeline] # capability yang disediakan
requires: [http_client, http_pipeline] # capability yang dibutuhkan
optional_requires: [storage]           # dipakai bila tersedia
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
  app_links:
    hosts: [kiln.dev]
    path_prefixes: [/profile]
  allow_backup: false
  min_sdk: 24
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
macos:
  entitlements:
    com.apple.security.network.client: true
  url_schemes: [kiln]
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

## Field penting

- `provides` dan `requires` memakai nama capability, bukan id extension.
- `exclusive: true` berarti hanya satu extension di kategori yang sama boleh
  terpasang.
- `slots` membuka titik sambung; `contributes` menempel ke slot yang dibuka
  extension lain. Item harus cocok dengan tipe slot.
- `when` membuat kontribusi hanya aktif bila semua capability tersedia.
- `prompts` bertipe `string`, `url`, `int`, `bool`, `enum`, `secret`, atau
  `multi`. Prompt `secret` tidak disimpan di `kiln.yaml`; nilainya disimpan di
  `env/*.json`.
- Patch native hanya diterapkan bila folder platform ada di proyek.
- `conditional` menerapkan blok native hanya bila semua jawaban prompt di `when`
  cocok; list dibandingkan per elemen.
- `manual_steps` dilacak `kiln doctor`.

## Validasi

```bash
kiln ext validate extensions/http_retry
```

Validator menolak id non-snake_case, semver salah, capability ganda, prompt
tanpa opsi enum/multi, requires terhadap capability sendiri, slot ganda, serta
permission, URL scheme, App Link host/path prefix, dan receiver Android yang
tidak valid atau duplikat.
