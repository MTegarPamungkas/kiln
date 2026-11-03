# supabase

Implementasi kontrak `kiln_core` di atas `supabase_flutter`: `AuthRepository`,
`SocialAuth`, `AccountManagement`, `RemoteDatabase`, dan `FileStorage`, plus
`TokenProvider`, jembatan sesi, dan penerima callback email.

- `SupabaseAuthRepository` memakai email dan password Supabase, menyimpan sesi
  di memori, dan meneruskan `onAuthStateChange` ke `authStateChanges`.
- `SupabaseSocialAuth` menukar ID token Google atau Apple lewat
  `signInWithIdToken`; tanpa sumber ID token, ekstensi membuka alur OAuth di
  browser dan menunggu callback deep link.
- `SupabaseAccountManagement` menangani reset password, verifikasi email, dan
  perubahan `display_name`/`avatar_url`.
- `SupabaseRemoteDatabase` memetakan `RemoteQuery` ke filter PostgREST dan
  memakai realtime untuk `watch`.
- `SupabaseFileStorage` memakai satu bucket dan selalu membuat signed URL.
- `SupabaseSessionBridge` meneruskan sesi ke `SessionController`, sedangkan
  `SupabaseTokenProvider` membaca access token sesi aktif.
- `SupabaseLinkHandler` menangani `code` (PKCE) dan `token_hash`/`type`
  (verifikasi email) lewat kontrak `DeepLinks`.

## Cara pasang

```bash
kiln ext add supabase
```

Isi prompt `url` dan `anon_key` dari dashboard Supabase. Setelah render,
lengkapi langkah manual di `extension.yaml`:

1. `configure_auth_redirect` — samakan `authRedirectUrl` dengan scheme yang
   dipakai extension `deep_link`.
2. `enable_realtime` — tambahkan tabel yang di-`watch` ke publikasi
   `supabase_realtime`.
3. `create_storage_bucket` — buat bucket `public` atau ubah
   `SupabaseConfig.storageBucket`.

## Contoh pemakaian

```dart
final auth = registry.read<AuthRepository>();
await auth.signIn(email: 'user@kiln.dev', password: 'password123');

final db = registry.read<RemoteDatabase>();
final tasks = await db.query(
  'tasks',
  query: const RemoteQuery(
    filters: [RemoteFilter('done', RemoteFilterOperator.equals, false)],
    orderBy: [RemoteOrder('title')],
    limit: 20,
  ),
);
```

Dokumentasi lanjutan:

- [Persiapan Supabase](docs/supabase-setup.md)
- [Row level security](docs/row-level-security.md)
- [Konfirmasi email dan redirect](docs/email-confirmation-and-redirects.md)
