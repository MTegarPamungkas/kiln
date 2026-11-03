# Social login

`SocialLogin.signIn(provider)` mengembalikan `SocialCredential` atau null bila
user membatalkan. Kegagalan SDK dilempar sebagai `Failure`.

```dart
final login = registry.read<SocialLogin>();

final credential = await login.signIn(SocialProvider.google);
if (credential != null) {
  await backendSocialAuth.signInWithCredential(credential);
}
```

## Provider

- Google tersedia di Android, iOS, macOS, dan web. Isi minimal satu client id:
  `google_server_client_id` untuk Android/web dan `google_ios_client_id` untuk
  iOS/macOS.
- Apple tersedia secara native di iOS dan macOS. Android dan web memerlukan
  `apple_service_id` serta `apple_redirect_uri` yang terdaftar di Apple.

Panel UI hanya menampilkan provider yang aktif, didukung platform, dan sudah
dikonfigurasi:

```dart
SocialLoginPanel(
  login: registry.read<SocialLogin>(),
  availability: registry.read<SocialAvailability>(),
  config: registry.read<SocialLoginConfig>(),
)
```

## Nonce

Apple menerima hash SHA-256 dari nonce acak. Simpan nonce asli hanya bila
server memverifikasi klaim `nonce` di identity token; extension ini tidak
menyimpannya.

## Sign out

Bila `AuthRepository` terpasang, module mendengarkan `authStateChanges` dan
memanggil `GoogleSignIn.signOut()` ketika sesi menjadi null. Apple tidak punya
sesi SDK yang perlu dibersihkan.
