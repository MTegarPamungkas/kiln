# Token refresh

## Kapan refresh

`TokenRefresher` memakai dua sumber kedaluwarsa:

1. `expiresAt` dari respons login (dihitung dari `expires_in` atau `expiresAt`).
2. `exp` JWT bila server tidak mengirim masa berlaku.

Token dianggap perlu refresh bila tersisa kurang dari 30 detik (leeway
`RestAuthConfig.refreshLeeway`).

## Single-flight

Semua pemanggil `accessToken()` yang menemukan token kedaluwarsa berbagi satu
`Future` refresh. Server hanya menerima satu permintaan refresh walau sepuluh
request HTTP berjalan bersamaan.

```dart
final token = await auth.tokenProvider.accessToken();
```

## Setelah 401

`UnauthorizedHandler` melakukan:

1. Memanggil `refreshAccessToken()`.
2. Bila token baru ada, mengulang request sekali dengan Bearer baru.
3. Bila refresh gagal atau request kedua tetap 401, memanggil `signOut()`.

`signOut()` menghapus token dan menandai sesi berakhir, sehingga guard
navigasi dapat mengarahkan user ke halaman masuk.

## Kegagalan

Refresh yang gagal melempar `Failure` dari pemetaan status server. Jaringan
putus tidak menghapus token; user bisa mencoba lagi saat online. Hanya
`signOut` eksplisit yang menghapus seluruh token.
