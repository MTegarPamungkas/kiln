# Logging

`AppLogger` adalah kontrak dari `kiln_core`. Extension ini menyediakan
implementasinya lewat `PipelineLogger`, yang memberi timestamp, menyaring
berdasarkan level, lalu meneruskan `LogRecord` ke `SinkPipeline`.

```dart
final logger = registry.read<AppLogger>();

logger.debug('memuat profil');
logger.info('profil dimuat', data: {'user': 'u-1'});
logger.warning('cache lama dipakai');
logger.error('sinkronisasi gagal', error: failure, stackTrace: stack);
```

## Level

| Flavor | Level bawaan |
| --- | --- |
| `development` | `trace` |
| `staging` | `debug` |
| `production` | `warning` |

Nilai ini berasal dari `LoggerConfig`. Bila extension `flavor` tidak terpasang,
module memakai development untuk build debug dan production untuk build release.

`LogLevelController` bisa diubah saat berjalan hanya di flavor non-production.
Di production, `setLevel` melempar `Failure` dengan kode
`validation.unsupported_value`; level yang dikonfigurasi tetap dipakai.

```dart
final levels = registry.read<LogLevelController>();
levels.setLevel(LogLevel.trace); // hanya non-production
```

## Sink

Sink aktif diatur oleh `LoggerConfig.activeSinks`:

- `console` mencetak satu baris teks.
- `memory` menyimpan N record terakhir untuk laporan bug dan test.
- `file` menulis ke `app.log` berputar di folder `logs` dokumen aplikasi.
- `breadcrumb` meneruskan warning dan error ke `CrashReporter`.

File sink hanya tersedia di VM. Build web memakai stub, jadi impor
`file_log_sink.dart` aman di semua platform.

## HTTP

Bila prompt `http_logging` aktif dan `HttpPipeline` terdaftar,
`HttpLogMiddleware` ditambahkan dengan prioritas 90. Middleware mencatat metode,
URL tanpa query dan user info, status, serta durasi. Header disamarkan dengan
`PiiRedactor`; body tidak pernah dicatat. Respons 4xx dicatat sebagai warning,
5xx dan error jaringan sebagai error, dan error tetap dilempar ulang.

## Debug dan ekspor

`DebugLogPage` menampilkan isi `MemoryLogSink` di flavor non-production.

```dart
final exporter = LogExporter(
  memory: registry.read<MemoryLogSink>(),
  file: registry.isRegistered<FileLogSink>()
      ? registry.read<FileLogSink>()
      : null,
);
final report = await exporter.export();
```

Laporan menggabungkan record memori dan isi berkas, lalu menyamarkan ulang
keduanya sebelum ditampilkan atau dibagikan.
