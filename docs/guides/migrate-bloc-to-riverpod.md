# Migrasi state management

`bloc` dan `riverpod` sama-sama exclusive di kategori `state`, sehingga hanya
satu yang bisa terpasang. Keduanya sudah tersedia di katalog bawaan.

## Langkah

1. `kiln remove bloc --yes` setelah memastikan file state tidak diedit.
2. `kiln add riverpod`.
3. Pindahkan fitur dari Cubit/Bloc ke provider/Notifier.
4. Ganti test state ke provider override dari `kiln_testing`.
5. Jalankan `kiln doctor` dan seluruh test.

Karena state management menyentuh `lib/bootstrap.dart` dan `lib/app`, lakukan
migrasi di awal proyek atau saat ada waktu untuk menyesuaikan fitur.
