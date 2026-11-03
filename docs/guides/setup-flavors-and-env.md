# Flavor dan environment

Target akhir:

- `flavors` menyediakan `AppFlavor` dan banner non-production lewat slot
  `app.wrappers`.
- `env` menyediakan `Env` bertipe dan file `env/*.example.json`.
- Nilai asli disimpan di `env/<flavor>.json` dan di-ignore Git.
- Jalankan dengan `--dart-define-from-file=env/<flavor>.json`.

Contoh config:

```yaml
extensions:
  env:
    keys:
      - {name: API_BASE_URL, type: url, required: true}
      - {name: ENABLE_LOGGING, type: bool, required: false}
```

Ingat: nilai `--dart-define` dapat diekstrak dari binary, jadi jangan menyimpan
kunci server di aplikasi klien.

Extension `flavors` dan `env` masuk fase tooling pada
[roadmap](../roadmap.md).
