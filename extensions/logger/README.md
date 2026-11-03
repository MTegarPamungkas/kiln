# logger

Implementasi `AppLogger` dari `kiln_core`: log bertingkat, sink yang dapat
disusun, penyamaran data pribadi, berkas log berputar, buffer memori, breadcrumb
crash, dan halaman log debug.

- `LoggerModule` mendaftarkan `AppLogger`, `LoggerConfig`, `LogLevelController`,
  `MemoryLogSink`, dan `FileLogSink` bila file sink aktif.
- Level mengikuti flavor: `development` (trace), `staging` (debug), dan
  `production` (warning). Tanpa extension `flavor`, build debug memakai level
  development dan build release memakai level production.
- `RedactingSink` menyamarkan pesan, data, dan teks error dengan `PiiRedactor`
  sebelum mencapai sink.
- `HttpLogMiddleware` mencatat metode, URL tanpa query, status, dan durasi;
  header `Authorization` disamarkan dan body tidak pernah dicatat.
- `DebugLogPage` hanya menampilkan isi `MemoryLogSink` di flavor non-production.

```dart
final logger = registry.read<AppLogger>();
logger.info('checkout selesai', data: {'order': 42});
```

Baca [docs/logging.md](docs/logging.md) untuk panduan pemakaian,
[docs/sinks.md](docs/sinks.md) untuk menulis sink sendiri, dan
[docs/what-not-to-log.md](docs/what-not-to-log.md) untuk daftar data yang tidak
boleh dicatat.
