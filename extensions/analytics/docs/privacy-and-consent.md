# Privasi dan persetujuan

## Kapan event dikirim

Extension ini opt-in. `ConsentGateAnalytics` adalah lapisan terluar dan
memeriksa `ConsentController.isGranted(ConsentCategory.analytics)` pada setiap
panggilan `capture` dan `identify`. Selama izin belum diberikan:

- tidak ada panggilan ke SDK PostHog;
- tidak ada scrubbing properti yang sia-sia;
- tidak ada event atau identitas yang dikirim.

Karena pemeriksaannya per panggilan, memberikan izin setelah aplikasi berjalan
langsung mengaktifkan pengiriman tanpa membangun ulang module. Menarik izin
juga langsung menghentikan event berikutnya.

`reset` selalu diteruskan ke SDK karena hanya menghapus identitas yang
tersimpan di perangkat dan tidak mengirim event.

## Apa yang disamarkan

`PiiScrubbingAnalytics` memakai `PiiRedactor` sebelum data mencapai gateway:

- properti event dan trait identitas diperiksa per kunci; kunci sensitif
  seperti `password`, `token`, `authorization`, `email`, dan `phone` diganti
  `[redacted]`;
- teks di dalam nilai juga dibersihkan dari email, token Bearer, dan JWT;
- map dan list diproses rekursif;
- `userId` tidak diubah karena berfungsi sebagai identitas pseudonim untuk
  menggabungkan event.

Penyamaran adalah lapisan pertahanan terakhir, bukan izin untuk mengumpulkan
PII. Jangan mengirim data pribadi yang tidak dibutuhkan produk.

## Menarik persetujuan

```dart
final consent = registry.read<ConsentController>();
consent.deny(ConsentCategory.analytics);
await registry.read<Analytics>().reset();
```

Setelah izin ditarik, panggilan analytics berikutnya tidak mengirim apa pun.
Panggil `reset` bila aplikasi juga ingin membersihkan identitas yang sudah
tersimpan pada SDK.
