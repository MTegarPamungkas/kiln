# notifications

Implementasi `Notifications` dari `kiln_core` di atas
`flutter_local_notifications`.

- Channel Android dibuat saat start; id dan ikon kecil berasal dari prompt.
- Izin notifikasi diminta lewat kontrak `Permissions` bila terpasang, lalu jatuh
  ke plugin bila kontrak tidak tersedia.
- `NotificationPayload` membawa route dan argumen bertipe sebagai JSON dengan
  batas ukuran.
- `NotificationTapHub` menggabungkan tap foreground, tap latar belakang, dan
  payload yang meluncurkan aplikasi.
- `ReminderScheduler` menjadwalkan ulang pengingat secara idempoten per kunci.
- `TimezoneResolver` memakai zona perangkat, bukan UTC.

Setelah install, receiver Android untuk penjadwalan sudah ditambahkan otomatis
lewat `android.receivers`. Bila `exact_alarms` dipilih, selesaikan langkah izin
alarm eksak di [docs/troubleshooting-delivery.md](docs/troubleshooting-delivery.md).
