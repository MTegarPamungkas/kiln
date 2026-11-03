# appwrite

Implementasi `AuthRepository`, `RemoteDatabase`, dan `FileStorage` dari
`kiln_core` di atas [Appwrite](https://appwrite.io).

- `AppwriteAuth` memakai `Account` Appwrite untuk masuk, daftar, keluar, dan
  memulihkan sesi yang masih aktif.
- `AppwriteAccountManagement` menangani reset password, verifikasi email, dan
  perubahan profil.
- `AppwriteSessionBridge` meneruskan sesi ke `SessionController` dan menyediakan
  `TokenProvider` berupa JWT Appwrite berumur pendek.
- `AppwriteRemoteDatabase` memetakan `RemoteQuery` ke query TablesDB dan
  meneruskan perubahan realtime lewat `watch`.
- `AppwriteFileStorage` mengunggah, mengunduh, menautkan, dan menghapus berkas
  di bucket yang dipilih.
- Semua panggilan SDK berada di balik gateway, sehingga aplikasi bisa menguji
  alurnya tanpa jaringan.

## Memasang

```bash
kiln add appwrite
```

Prompt yang diminta: `endpoint`, `project_id`, `database_id`, dan `bucket_id`.
Setelah install, ikuti [docs/appwrite-setup.md](docs/appwrite-setup.md) dan
selesaikan dua langkah manual yang dicatat `kiln doctor`: menambahkan platform
aplikasi dan mendaftarkan redirect URL `kiln://auth/recovery` serta
`kiln://auth/verify`.

## Contoh pemakaian

```dart
final auth = registry.read<AuthRepository>();
final session = await auth.signIn(
  email: 'user@kiln.dev',
  password: 'password123',
);

final database = registry.read<RemoteDatabase>();
final tasks = await database.query(
  'tasks',
  query: const RemoteQuery(
    filters: [RemoteFilter('done', RemoteFilterOperator.equals, false)],
    orderBy: [RemoteOrder('title')],
    limit: 20,
  ),
);

final storage = registry.read<FileStorage>();
final stored = await storage.upload(
  FileUpload(path: 'avatars/user-1.png', bytes: bytes),
  onProgress: (progress) => debugPrint('${progress * 100}%'),
);
```

Pemetaan query, izin dokumen, dan perbedaan perilaku dibahas di
[docs/collections-and-permissions.md](docs/collections-and-permissions.md) dan
[docs/backend-swap-notes.md](docs/backend-swap-notes.md).
