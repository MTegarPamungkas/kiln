# Deep link dan routing

## Alur

1. Extension `deep_link` mendaftarkan implementasi `DeepLinks`.
2. `GoRouterModule.ready` memanggil `AppRouter.start()`.
3. `start()` membaca `DeepLinks` dan `Notifications` lewat `readOrNull`.
4. Setiap tautan dipetakan menjadi lokasi, lalu `router.go` dipanggil bila
   lokasinya berbeda dari lokasi saat ini.

Pembacaan dilakukan saat `ready`, bukan saat `register`, agar provider yang
didaftarkan setelah modul navigasi tetap terdeteksi. Bila kontraknya tidak ada,
integrasi dilewati tanpa error.

## Deep link

`DeepLinkRouteMapper` menerima URI dari `DeepLinks.initialLink` dan stream
`DeepLinks.links`.

| Tautan | Lokasi |
| --- | --- |
| `https://example.com/orders/42?tab=items` | `/orders/42?tab=items` |
| `myapp://orders/42` | `/orders/42` |
| `myapp:///orders/42` | `/orders/42` |
| `myapp://explore?ref=email` | `/explore?ref=email` |
| `mailto:halo@example.com` | diabaikan |
| `https://example.com` | diabaikan |

Skema `mailto`, `tel`, `sms`, `file`, `javascript`, `data`, dan `about`
diabaikan. Query dan fragment dipertahankan karena sering dipakai untuk
pelacakan atau detail tambahan.

Tautan awal diproses sebelum frame pertama. Tautan yang tiba saat aplikasi
sudah berjalan diproses lewat stream. Tautan yang menunjuk lokasi yang sama
tidak memicu navigasi ulang.

## Notifikasi

`NotificationRouteMapper` menerima `NotificationTap` dari stream
`Notifications.taps`. Payload dapat berupa route biasa atau JSON:

```text
/orders/42
{"route":"/orders/42","orderId":42}
```

Payload kosong, JSON rusak, nilai `route` yang bukan string, dan teks tanpa
awalan `/` diabaikan. Extension ini tidak mengimpor extension notifications;
ia hanya memakai kontrak `Notifications` dan `NotificationTap` dari
`kiln_core`.

## Menguji tautan

```dart
final deepLinks = FakeDeepLinks(
  initialLink: Uri.parse('https://example.com/orders/42'),
);
final registry = createTestRegistry(deepLinks: deepLinks);
final appRouter = AppRouter(registry: registry)..start();
```

Gunakan `FakeDeepLinks.emit` dan `FakeNotifications.emitTap` untuk menguji
tautan berikutnya. Periksa lokasi dengan:

```dart
appRouter.router.routerDelegate.currentConfiguration.uri.path
```

## Batasan

- Hanya tautan yang sudah dikenal router yang ditampilkan; sisanya masuk ke
  `NotFoundPage`.
- Parameter path harus dideklarasikan pada `AppRoute.path`, misalnya
  `/orders/:id`.
- Deep link tidak melewati guard; redirect tetap berlaku, termasuk ke
  `/sign-in` untuk pengunjung yang belum masuk.
