# Navigasi

## Apa yang didaftarkan

`GoRouterModule` mendaftarkan tiga hal ke Registry:

| Tipe | Isi |
| --- | --- |
| `RouterConfig<Object>` | Instance `GoRouter` yang dibaca `AppShell` |
| `AppRouter` | Pemilik router, observer, dan integrasi tautan |
| `AppRouterConfig` | Lokasi awal, log diagnostik, error builder, observer tambahan |

Slot `router.routes` dibuka oleh modul. Item slot bertipe `AppRoute` dari
`app_basic`, sehingga fitur tidak perlu bergantung pada `go_router`.

## Route bawaan

`AppRoutes` menyimpan path dan nama route milik extension:

- `/` dengan nama `home`
- `/explore` dengan nama `explore`
- `/sign-in` dengan nama `signIn`

`/` dan `/explore` berada di dalam `ShellRoute` dengan `NavigationBar`.
`/sign-in` berada di luar shell agar tidak menampilkan navigasi bawah.

Ganti isi `_HomeTab` dan `_ExploreTab` di `shell_scaffold.dart`, atau ganti
seluruh `buildShellRoute()` dengan route aplikasi. Jika shell tidak dipakai,
hapus pemanggilan `buildShellRoute()` dari `AppRouter` dan daftarkan route
tab secara langsung.

## Menambah route lewat slot

```dart
registry
    .read<SlotRegistry>()
    .open<AppRoute>(SlotNames.routerRoutes)
    .add(
      AppRoute(
        path: '/orders/:id',
        name: 'order',
        builder: (context) => const OrderDetailPage(),
      ),
    );
```

`RouteSlot` mengubah setiap `AppRoute` menjadi `GoRoute` dengan path, nama, dan
builder yang sama. Urutan item mengikuti prioritas slot, lalu urutan
penambahan.

Parameter path dapat dibaca dari `GoRouterState` di dalam builder:

```dart
AppRoute(
  path: '/orders/:id',
  name: 'order',
  builder: (context) => OrderDetailPage(
    orderId: GoRouterState.of(context).pathParameters['id']!,
  ),
);
```

## Navigasi

Di dalam widget yang berada di bawah `MaterialApp.router`, gunakan extension
dari `go_router`:

```dart
context.go('/orders/42');
context.pushNamed('order', pathParameters: {'id': '42'});
context.pop();
```

Di luar widget tree, misalnya dari sebuah controller, gunakan
`registry.read<AppRouter>().router`.

## Transisi

`buildRoutePage` di `route_transitions.dart` memilih transisi sesuai platform:
slide untuk iOS dan macOS, fade dengan geser kecil untuk Android, dan fade
untuk Windows serta Linux. Route bawaan `/sign-in` memakainya. Gunakan fungsi
yang sama di `pageBuilder` untuk route yang membutuhkan animasi khusus.

## Konfigurasi

```dart
final config = AppRouterConfig(
  initialLocation: '/explore',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => const AppErrorPage(),
);
```

Bila `errorBuilder` tidak diisi, `NotFoundPage` ditampilkan. Jangan aktifkan
`debugLogDiagnostics` di build release.
