# Sinks

Sink adalah tujuan akhir sebuah `LogRecord`. Kontraknya kecil:

```dart
abstract interface class LogSink {
  FutureOr<void> write(LogRecord record);
  FutureOr<void> flush();
}
```

`SinkPipeline` mengirim setiap record ke semua sink secara berurutan. Sink yang
melempar error, sinkron maupun asinkron, dilaporkan lewat `onFailure` dan tidak
menghentikan sink berikutnya. Jangan mencatat kegagalan sink melalui pipeline
yang sama; pakai writer fallback agar tidak terjadi rekursi.

Sink kustom:

```dart
final class HttpCollectorSink implements LogSink {
  HttpCollectorSink(this.client);

  final HttpClient client;
  final List<LogRecord> buffer = <LogRecord>[];

  @override
  FutureOr<void> write(LogRecord record) {
    buffer.add(record);
    return null;
  }

  @override
  Future<void> flush() async {
    if (buffer.isEmpty) return;
    // Kirim buffer ke backend, lalu kosongkan.
  }
}
```

## Urutan decorator

Bungkus sink dalam `RedactingSink` sebelum sink tersebut menyimpan atau
mengirim data pribadi. Urutan yang disarankan:

```text
PipelineLogger -> SinkPipeline -> RedactingSink -> MemoryLogSink
                                              -> FileLogSink
                                              -> BreadcrumbSink
```

Module sudah melakukan ini untuk semua sink bila `redactionEnabled` bernilai
true. `LogExporter` menyamarkan ulang saat membaca, sehingga laporan tetap aman
meski record lama berasal dari sink lain.

## Catatan implementasi

- Tulis record secara serial bila sink memiliki state, seperti berkas berputar.
- `flush()` harus menunggu semua tulisan yang sudah diterima.
- Jangan memblokir pemanggil `write()` dengan pekerjaan jaringan yang lama;
  antrekan dan selesaikan di `flush()`.
- `MemoryLogSink` memakai buffer cincin: kapasitas tetap dan record tertua
  dibuang lebih dulu.
