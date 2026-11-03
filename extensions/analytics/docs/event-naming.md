# Nama event dan properti

## Nama event

Pakai pola `object verb` dalam huruf kecil dan bahasa Inggris, misalnya
`project created`, `invite sent`, atau `report exported`. Nama event adalah API
publik: dashboard dan funnel bergantung padanya, jadi jangan mengganti nama
event yang sudah dikirim. Tambahkan event baru bila maknanya berubah.

- Satu event mewakili satu kejadian yang sudah terjadi.
- Jangan menyertakan id pengguna, email, atau nilai acak di nama event.
- Jangan membuat event dari setiap perubahan state internal; pilih momen yang
  bermakna bagi produk.

## Properti

Gunakan `snake_case` untuk kunci properti, misalnya `plan`, `seat_count`, dan
`created_at`. Nilai harus JSON-like:

- `String`, `bool`, dan angka finite dikirim apa adanya.
- `DateTime` menjadi string ISO-8601.
- `Duration` menjadi jumlah milidetik.
- `Enum` menjadi `name`.
- `Iterable` dan `Map` diterjemahkan rekursif; kunci map harus `String`.
- `null` dibuang. Nilai lain, termasuk objek bebas dan angka non-finite,
  menghasilkan `Failure` dengan `FailureKind.validation`.

## Event bertipe

`AnalyticsEvent` membawa nama dan properti sebagai satu nilai, dan
`captureEvent` meneruskannya ke implementasi `Analytics` mana pun:

```dart
const projectCreated = AnalyticsEvent(
  'project created',
  properties: <String, Object?>{'plan': 'pro', 'seat_count': 3},
);

await registry.read<Analytics>().captureEvent(projectCreated);
```

Simpan event yang dipakai di beberapa tempat sebagai konstanta agar nama dan
bentuk propertinya konsisten. Jangan menaruh PII di properti; lihat
[privacy-and-consent.md](privacy-and-consent.md).
