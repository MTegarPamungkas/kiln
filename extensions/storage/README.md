# storage

Implementasi `Storage` dari `kiln_core` di atas `shared_preferences`.

Extension ini menyediakan capability `storage`. Kode aplikasi membaca kontrak
dari Registry; tidak ada fasad statis.

Isi brick:

- gateway `SharedPreferencesAsync` yang bisa di-fake,
- `SharedPreferencesStorage` dengan prefix per aplikasi,
- `StorageKey<T>` bertipe,
- `TtlStorage` memakai `Clock`,
- `NamespacedStorage` untuk pemilik lain seperti `http_cache`,
- `StorageMigrator` untuk versi skema key.
