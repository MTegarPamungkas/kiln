# Environment

```dart
final env = registry.read<Env>();

final baseUrl = env.uri(EnvKeys.apiBaseUrl);
final debugTools = env.boolValue(EnvKeys.enableDebugTools) ?? false;
```

Nilai berasal dari `--dart-define`:

```bash
flutter run --dart-define=api_base_url=https://api.kiln.dev
```

Atau dari file JSON:

```bash
flutter run --dart-define-from-file=env/development.json
```

## Key

| Key | Tipe | Wajib | Rahasia |
| --- | --- | --- | --- |
| `api_base_url` | URI | ya | tidak |
| `api_key` | string | tidak | ya |
| `feature_flags` | string | tidak | tidak |
| `enable_debug_tools` | bool | tidak | tidak |

Key yang dipilih saat install masuk ke `EnvSchema.defaults`. `BuildEnv` menolak
membaca key yang tidak ada di skema.

## Menambah key

1. Tambahkan konstanta di `env_keys.dart`.
2. Tambahkan `String.fromEnvironment` di `build_env_values.dart`.
3. Tambahkan `EnvKeySpec` di `env_schema.dart`.
4. Tambahkan key ke file `env/*.example.json`.
5. Tambahkan key ke `EnvSchema.activeNames` bila perlu.

## Validasi

`EnvModule.ready` memanggil validator. Semua key wajib yang kosong dilaporkan
sekaligus, sehingga aplikasi tidak gagal satu per satu.

## Debug

`EnvDebugPage` menampilkan key aktif dan menyamarkan nilai rahasia. Halaman ini
otomatis disembunyikan di flavor production.
