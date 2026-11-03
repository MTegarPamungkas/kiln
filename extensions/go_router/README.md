# go_router

Navigasi deklaratif untuk aplikasi Kiln di atas `go_router`. Extension ini
mengisi seam `RouterConfig<Object>` yang dibaca `app_shell.dart`, jadi
`app.dart` tidak perlu diedit.

- `GoRouterModule` mendaftarkan `RouterConfig<Object>`, `AppRouter`, dan
  `AppRouterConfig`, lalu membuka slot `router.routes`.
- `AppRouter` membangun `GoRouter` dari lokasi awal, route slot, guard, dan
  `SessionController`.
- `AuthRedirect` mengirim pengunjung yang belum masuk ke `/sign-in` dan
  memindahkan pengunjung yang sudah masuk menjauh dari halaman itu.
- `DeepLinkRouteMapper` dan `NotificationRouteMapper` mengubah tautan masuk dan
  payload notifikasi menjadi lokasi route.
- `NavigationObserver` mencatat navigasi ke `AppLogger` dan mengirim screen ke
  `Analytics` bila kontraknya tersedia.
- `NotFoundPage`, `ShellScaffold`, dan `route_transitions.dart` menyediakan UI
  awal yang bisa diganti aplikasi.

## Pasang

```bash
kiln ext add go_router
```

Extension ini `exclusive` untuk kategori navigasi dan menyediakan capability
`navigation`. `deep_links`, `notifications`, `analytics`, dan `logger` bersifat
opsional; integrasinya aktif otomatis bila kontraknya terdaftar di Registry.

## Menambah route

Fitur lain tidak perlu mengimpor `go_router`. Cukup kontribusikan `AppRoute`
dari `app_basic` ke slot `router.routes`:

```dart
final slots = registry.read<SlotRegistry>();
slots.open<AppRoute>(SlotNames.routerRoutes).add(
  AppRoute(
    path: '/orders/:id',
    name: 'order',
    builder: (context) => const OrderDetailPage(),
  ),
);
```

Route harus dikontribusikan sebelum `GoRouterModule.register` dijalankan.
Modul yang menyediakan route dapat dideklarasikan sebagai dependency capability
`navigation` agar urutannya benar.

## Navigasi dari widget

```dart
context.go('/orders/42');
context.push('/orders/42');
context.pop();
```

Panduan lengkap ada di [docs/navigation.md](docs/navigation.md),
[docs/route-guards.md](docs/route-guards.md), dan
[docs/deep-links-and-routing.md](docs/deep-links-and-routing.md).
