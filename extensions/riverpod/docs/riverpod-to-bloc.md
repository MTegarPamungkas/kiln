# Migrasi Riverpod ke Bloc

Kedua extension state bersifat exclusive. Langkah umum:

1. Pindahkan provider/Notifier ke Cubit/Bloc.
2. Ganti `ConsumerWidget` dengan `BlocBuilder`.
3. Pertahankan kontrak dan Registry; hanya lapisan state yang berubah.
4. `kiln remove riverpod`, lalu `kiln add bloc`.

Lakukan migrasi di awal proyek atau saat ada waktu untuk menyesuaikan fitur.
