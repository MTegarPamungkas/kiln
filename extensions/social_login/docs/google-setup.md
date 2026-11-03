# Google setup

1. Buat OAuth client di Google Cloud Console.
2. Daftarkan package name dan SHA-1 Android.
3. Buat client id iOS dengan bundle id aplikasi.
4. Isi prompt:

```bash
kiln config set google_server_client_id=123-abc.apps.googleusercontent.com
kiln config set google_ios_client_id=123-def.apps.googleusercontent.com
```

`google_server_client_id` dipakai di Android dan web; `google_ios_client_id`
dipakai di iOS dan macOS. Bila keduanya kosong, tombol Google tidak muncul dan
`signIn` melempar `Failure(auth.provider_disabled)`.

Google Sign-In 7 memakai `GoogleSignIn.instance.initialize()` sekali. Gateway
memanggilnya pada sign-in pertama, jadi tidak perlu inisialisasi manual.
