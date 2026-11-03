# Typed key dan migrasi

```dart
final notificationsEnabled = StorageKey<bool>(
  name: 'notifications_enabled',
  encode: (value) => value,
  decode: (value) => value as bool,
  defaultValue: true,
);
```

`StorageMigrator` menyimpan versi skema di key `schema_version` dan menjalankan
langkah migrasi saat start. Tambahkan langkah baru tanpa menghapus langkah lama.
