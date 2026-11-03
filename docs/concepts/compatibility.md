# Kompatibilitas

Manifest extension dapat membatasi:

```yaml
compatibility:
  kiln: ">=0.1.0 <0.2.0"
  dart: ">=3.9.0"
  flutter: ">=3.35.0"
```

`kiln doctor` memeriksa rentang ini terhadap versi CLI dan Dart yang berjalan.
Resolver juga dapat menolak platform yang tidak didukung lewat `platforms`.

Aturan versi:

- Extension memakai semver.
- Lockfile mencatat versi tepat yang terpasang.
- Upgrade multi-versi dan migration runner menunggu katalog registry.
- Constraint dependency extension ditulis di `dependencies` dan ditambahkan ke
  `pubspec.yaml` proyek pengguna.
