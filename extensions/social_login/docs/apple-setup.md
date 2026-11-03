# Apple setup

## iOS dan macOS

1. Aktifkan capability Sign in with Apple pada target Runner.
2. Extension menambahkan entitlement `com.apple.developer.applesignin`.
3. Tidak perlu service id untuk sign-in native.

## Android dan web

1. Buat Services ID di Apple Developer.
2. Daftarkan redirect URI yang dipakai aplikasi.
3. Isi prompt:

```bash
kiln config set apple_service_id=com.example.app.service
kiln config set apple_redirect_uri=https://example.com/callback
```

Tanpa service id dan redirect, provider Apple disembunyikan di Android dan web.
Di iOS dan macOS provider tetap tersedia karena memakai dialog native.

## Nonce

Nonce acak di-hash SHA-256 sebelum dikirim ke Apple. Bila backend memeriksa
klaim `nonce`, bandingkan dengan hash nonce asli yang disimpan saat memulai
alur; extension tidak menyimpan nonce asli.
