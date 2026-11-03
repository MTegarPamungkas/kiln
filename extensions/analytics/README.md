# analytics

Implementasi `Analytics` dari `kiln_core` di atas PostHog.

- Event dan identitas hanya dikirim setelah kategori `analytics` pada
  `ConsentController` diberikan.
- Properti disanitasi menjadi nilai JSON-like, lalu disamarkan dengan
  `PiiRedactor` sebelum menyentuh SDK.
- `SessionIdentityListener` memanggil `identify` saat masuk dan `reset` saat
  keluar, mengikuti `SessionController`.
- Bila API key kosong atau flavor saat ini tidak diizinkan, module memakai
  `NoopAnalytics` sehingga kode aplikasi tetap aman memanggil analytics.
- Semua akses SDK berada di balik `AnalyticsGateway`, jadi test tidak
  menyentuh plugin maupun jaringan.

Pasang extension ini bersama module analytics di daftar module aplikasi, lalu
baca [docs/analytics.md](docs/analytics.md) untuk konfigurasi dan pemakaian.
