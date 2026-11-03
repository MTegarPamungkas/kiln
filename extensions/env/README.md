# env

Konfigurasi build-time bertipe dari `--dart-define`.

- `BuildEnv` membaca nilai yang dikompilasi ke aplikasi, bukan file saat runtime.
- `EnvSchema` mendefinisikan key aktif, tipe, wajib, dan rahasia.
- `EnvValidator` mengumpulkan semua key wajib yang hilang menjadi satu
  `Failure(configuration)`.
- `EnvX` menyediakan pembaca `uri`, `duration`, `boolValue`, dan `enumValue`.
- `EnvDescribe` menyamarkan nilai rahasia untuk log.
- `EnvDebugPage` hanya tampil di flavor non-production.

Key yang tersedia saat ini: `api_base_url`, `api_key`, `feature_flags`, dan
`enable_debug_tools`. Lihat [docs/env.md](docs/env.md) untuk menambah key.
