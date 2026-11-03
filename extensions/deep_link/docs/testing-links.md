# Menguji tautan

Selalu uji dengan aplikasi yang sudah terpasang, bukan hanya dari kode test.

## Android

Scheme kustom:

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "kiln://profile/42" com.example.app
```

Universal link:

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://kiln.dev/app/42" com.example.app
```

Tanpa nama package, Android memilih aplikasi yang cocok; ini menguji intent
filter sekaligus. Periksa verifikasi domain dengan:

```bash
adb shell pm get-app-links com.example.app
```

## iOS

Simulator:

```bash
xcrun simctl openurl booted "kiln://profile/42"
xcrun simctl openurl booted "https://kiln.dev/app/42"
```

Perangkat: kirim tautan lewat Notes atau Safari. Universal link tidak dapat
diuji dengan `openurl` pada semua versi simulator; gunakan perangkat bila
perilaku terasa tidak konsisten.

## Yang perlu diperiksa

- Tautan yang sama dua kali berurutan diabaikan (jendela deduplikasi).
- Tautan dari host lain ditolak tanpa crash.
- Path di luar `path_prefixes` ditolak.
- Tautan yang tiba sebelum layar pertama siap tetap sampai ke router.
- Meluncurkan aplikasi dari tautan hanya menavigasi sekali (`initialLink`).
- Parameter `utm_*` hilang dari URI yang diterima listener.
