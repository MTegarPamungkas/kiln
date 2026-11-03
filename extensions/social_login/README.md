# social_login

Jalur masuk Google dan Apple yang mengembalikan `SocialCredential` untuk
backend `SocialAuth` yang terpasang.

- Gateway Google dan Apple dapat di-fake di test.
- `SocialLoginConfig` menyimpan client id dan provider yang aktif.
- `NonceGenerator` membuat nonce acak dan hash SHA-256 untuk Apple.
- `SocialAvailability` menyaring provider sesuai platform.
- `SocialSignOutListener` mengeluarkan sesi Google saat `AuthRepository`
  memanggil signOut.
- `SocialLoginButtons` dan `SocialLoginPanel` siap dipakai.

Setup Google: [docs/google-setup.md](docs/google-setup.md). Setup Apple:
[docs/apple-setup.md](docs/apple-setup.md).
