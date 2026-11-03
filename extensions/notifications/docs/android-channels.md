# Android channels

Android 8.0 dan lebih baru mengelompokkan notifikasi ke channel. User dapat
mengatur suara dan pentingnya per channel, jadi channel harus dibuat sekali
dengan id yang stabil.

```dart
NotificationChannels(
  specs: <NotificationChannelSpec>[
    const NotificationChannelSpec(
      id: 'orders',
      name: 'Pesanan',
      description: 'Perubahan status pesanan',
      importance: NotificationImportance.high,
    ),
  ],
);
```

Aturannya:

- Jangan mengganti id channel yang sudah dirilis; buat channel baru.
- Importance channel tidak bisa dinaikkan setelah dibuat; user memegang
  kendali terakhir.
- Nama dan deskripsi channel terlihat di pengaturan sistem, jadi tulis dengan
  bahasa user.

`flutter_local_notifications` membuat channel saat notifikasi pertama
ditampilkan, tetapi extension ini juga membuat semua channel saat start agar
channel kosong tetap muncul di pengaturan aplikasi.
