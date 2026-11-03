# Notifications

`Notifications` menampilkan, menjadwalkan, dan membatalkan notifikasi lokal.
Kontraknya ada di `kiln_core`; extension ini menyediakan implementasinya.

```dart
final notifications = registry.read<Notifications>();

await notifications.requestPermission();
await notifications.show(
  const NotificationMessage(
    id: 1,
    title: 'Pesanan siap',
    body: 'Pesanan #42 bisa diambil',
    payload: '{"route":"/orders/42"}',
  ),
);
```

## Izin

`requestPermission()` memakai kontrak `Permissions` bila extension `permission`
terpasang. Bila tidak, ia memanggil plugin langsung. Di iOS dan macOS, izin
tidak diminta saat start; panggil `requestPermission()` pada momen yang tepat,
misalnya setelah user menekan tombol pengingat.

## Tap

`taps` mengirim `NotificationTap` untuk tap foreground, tap aksi latar
belakang, dan payload yang meluncurkan aplikasi. Baca payload dengan
`NotificationPayload.tryDecode(tap.payload)` lalu teruskan route-nya ke
navigasi.

```dart
final subscription = notifications.taps.listen((tap) {
  final payload = NotificationPayload.tryDecode(tap.payload);
  if (payload?.route != null) {
    router.go(payload!.route!);
  }
});
```

## Channel

Channel android didefinisikan di `NotificationChannels`. Tambahkan channel baru
di sana, lalu tampilkan notifikasi dengan `channelId`. Lihat
[android-channels.md](android-channels.md).

## Penjadwalan

Gunakan `ReminderScheduler` agar jadwal yang sama tidak dibuat berulang setiap
start. Lihat [scheduling-and-timezones.md](scheduling-and-timezones.md).
