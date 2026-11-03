# Scheduling and timezones

`NotificationMessage` memakai `DateTime`. Saat dijadwalkan, extension
mengubahnya ke `TZDateTime` dengan zona perangkat yang dibaca
`TimezoneResolver` dari `flutter_timezone`.

```dart
final scheduler = ReminderScheduler(notifications: notifications);

await scheduler.schedule(
  key: 'hydration',
  title: 'Minum air',
  body: 'Sudah delapan jam sejak terakhir',
  when: DateTime(2026, 11, 2, 20),
  channelId: 'kiln_default_reminders',
);
```

Sifat yang dijamin:

- Kunci yang sama dengan isi dan waktu yang sama tidak dijadwalkan ulang.
- Kunci yang sama dengan waktu berbeda membatalkan jadwal lama lebih dahulu.
- Setiap kunci mendapat id stabil dari `NotificationIdAllocator`, sehingga
  memanggil `schedule` setiap start tidak membuat duplikat.

Zona waktu perangkat bisa berubah. Jadwal yang sudah dibuat tetap memakai
zona saat dijadwalkan; jalankan kembali `TimezoneResolver.configure()` dan
susun ulang pengingat setelah perubahan zona bila aplikasi membutuhkannya.

Di Android, penjadwalan bergantung pada receiver dan mode alarm. Lihat
[troubleshooting-delivery.md](troubleshooting-delivery.md).
