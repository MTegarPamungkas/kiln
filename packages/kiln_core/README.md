# kiln_core

Kontrak dan runtime dasar untuk aplikasi Kiln.

Isi utama:

- kontrak HTTP, storage, auth, platform, observability, dan konfigurasi;
- `Failure`, `FailureCode`, dan `Result<T>`;
- `Registry`, `KilnModule`, `ModuleGraph`, `KilnBootstrap`, `OrderedSlot`;
- `SessionController`, `ConsentController`, `PiiRedactor`, `Clock`,
  `Debouncer`.

Package ini tidak bergantung pada plugin Flutter. Aplikasi dan extension hanya
boleh mengenal kontrak di sini.

```dart
final registry = await KilnBootstrap.run(modules: kilnModules());
final client = registry.read<HttpClient>();
```

Lihat [docs/architecture.md](../../docs/architecture.md).
