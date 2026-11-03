# Konfirmasi email dan redirect

Supabase mengirim user kembali ke aplikasi lewat dua bentuk tautan:

- `?code=...` untuk alur PKCE, misalnya login OAuth dan reset password.
- `?token_hash=...&type=...` untuk konfirmasi email, invite, dan magic link.

`SupabaseLinkHandler` membaca keduanya dari kontrak `DeepLinks`, lalu memanggil
`exchangeCodeForSession` atau `verifyOtp`. Bila extension `deep_link` tidak
terpasang, handler tidak melakukan apa pun dan aplikasi harus menangani tautan
sendiri.

## 1. Samakan scheme

`SupabaseConfig.authRedirectUrl` bawaannya `kiln-auth://auth-callback` dan
manifest extension mendaftarkan scheme `kiln-auth` untuk Android dan iOS.
Konfigurasikan extension `deep_link` dengan scheme yang sama:

```yaml
# extension.yaml deep_link
prompts:
  - name: scheme
    default: kiln-auth
```

Bila scheme diganti, ubah juga `authRedirectUrl` di `supabase_config.dart` dan
daftarkan scheme itu pada manifest extension `deep_link`.

## 2. Daftarkan URL di dashboard

Di **Authentication > URL configuration**:

- **Site URL** diisi halaman aplikasi atau `kiln-auth://auth-callback`.
- **Redirect URLs** tambahkan setiap redirect yang dipakai, misalnya
  `kiln-auth://auth-callback`.

Supabase menolak `redirectTo` yang tidak ada di daftar ini.

## 3. Aktifkan konfirmasi email

Di **Authentication > Providers > Email** aktifkan **Confirm email**. Setelah
itu `signUp` mengembalikan sesi kosong dan extension melempar
`Failure(auth.email_not_verified)`. User harus membuka tautan konfirmasi lebih
dulu, kemudian `signIn` bisa dipakai.

## 4. Alur reset password

```dart
final account = registry.read<AccountManagement>();
await account.sendPasswordResetEmail('user@kiln.dev');
```

Tautan dari email berisi `token_hash` dan `type=recovery`. Setelah handler
menukarnya menjadi sesi, tampilkan layar ganti password. Kontrak
`AccountManagement` tidak memuat ganti password, jadi pakai gateway Supabase
yang didaftarkan modul:

```dart
final gateway = registry.read<SupabaseGateway>();
await gateway.updateUser(password: 'password-baru');
```

Untuk OAuth, panggil `SocialAuth.signIn(SocialProvider.google)`. Extension
membuka browser, menunggu sesi dari callback, dan mengembalikan `null` bila user
membatalkan atau waktu tunggu habis.

## 5. Mengamati kegagalan callback

Kegagalan yang tidak bisa dilempar ke pemanggil dikirim ke
`SupabaseLinkHandler.failures`:

```dart
final handler = registry.read<SupabaseLinkHandler>();
handler.failures.listen((failure) {
  // failure.kind == FailureKind.authentication untuk error Supabase
});
```

Tautan tanpa parameter auth (misalnya tautan biasa ke halaman aplikasi)
diabaikan, sehingga extension `deep_link` tetap bisa memakainya untuk navigasi.
