# Migrasi Bloc ke Riverpod

Kedua extension state bersifat exclusive. Langkah umum:

1. Pindahkan state per fitur ke provider/Notifier.
2. Ganti `BlocBuilder` dengan `Consumer`/`ConsumerWidget`.
3. Pertahankan kontrak dan Registry; hanya lapisan state yang berubah.
4. Jalankan `kiln remove bloc` lalu `kiln add riverpod`.

Karena perubahan menyentuh wrapper aplikasi dan test, lakukan di awal proyek
atau saat ada waktu untuk menyesuaikan fitur.
