# rest_auth

`AuthRepository` di atas `HttpClient` dan `SecureStorage`.

- `RestAuth` mengirim email dan kata sandi ke endpoint login/register,
  menyimpan token, lalu memancarkan `AuthSession`.
- `TokenRefresher` melakukan refresh single-flight: permintaan paralel berbagi
  satu hasil refresh.
- `JwtExpiry` membaca `exp` tanpa verifikasi untuk refresh sebelum token mati.
- `AuthMiddleware` menambahkan header Bearer (priority 10);
  `UnauthorizedHandler` refresh sekali, mengulang satu request, lalu signOut.
- `RestAccountManagement` memakai endpoint opsional reset password dan
  verifikasi email.
- `RestSessionBridge` mengisi `SessionController` untuk guard navigasi.

Bentuk JSON server ada di [docs/server-contract.md](docs/server-contract.md),
alur refresh di [docs/token-refresh.md](docs/token-refresh.md).
