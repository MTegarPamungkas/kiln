# REST auth

Extension ini memasang `AuthRepository` tanpa backend SDK. Semua endpoint
diisi lewat prompt dan dapat diganti tanpa mengubah kode fitur.

```dart
final auth = registry.read<AuthRepository>();

final session = await auth.signIn(
  email: 'user@kiln.dev',
  password: 'password123',
);
```

## Endpoint

Prompt `base_url` ditambah path login, register, refresh, logout, dan me.
`RestAuthConfig.endpoint` menggabungkan base URL dengan path sehingga
`https://api.kiln.dev/v1` dan `/auth/login` menjadi
`https://api.kiln.dev/v1/auth/login`.

Dua endpoint opsional tidak punya prompt:

- `forgotPasswordPath`
- `verifyEmailPath`

Isi keduanya lewat `RestAuthConfig` di kode bootstrap bila backend menyediakan
reset password dan verifikasi email.

## Token

Token disimpan di `SecureStorage` dengan kunci berawalan `rest_auth.`. User
terakhir juga di-cache agar aplikasi bisa dibuka offline; saat online,
`initialize()` memuat ulang profil dari endpoint me.

## HTTP

Bila `http_pipeline` tersedia, module menambahkan dua middleware:

| Priority | Middleware | Tugas |
| --- | --- | --- |
| 10 | `AuthMiddleware` | Menambahkan `Authorization: Bearer` |
| 11 | `UnauthorizedHandler` | Refresh, ulang sekali, signOut bila ditolak |

Lihat [token-refresh.md](token-refresh.md) untuk detail alur refresh.
