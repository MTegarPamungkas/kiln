# Route guard

## Interface

Guard adalah aturan redirect sinkron yang dievaluasi sebelum route tampil:

```dart
abstract interface class RouteGuard {
  String? redirect(RouteGuardContext context);
}
```

`RouteGuardContext` membawa `location`, `name`, dan `isAuthenticated`. Guard
tidak boleh memanggil `go` atau `push` sendiri; cukup kembalikan lokasi tujuan.
Nilai `null` berarti guard ini tidak keberatan dan evaluasi berlanjut.

## Urutan

`evaluateRouteGuards` menjalankan guard sesuai urutan penyusunan dan berhenti
pada redirect pertama:

```dart
final guards = <RouteGuard>[
  MaintenanceGuard(config),
  const AuthRedirect(),
];
```

Guard yang mengembalikan lokasi yang sama dianggap tidak melakukan redirect,
sehingga tidak terjadi loop. Guard yang lambat sebaiknya membaca data yang
sudah tersedia; redirect router tidak menunggu proses jaringan.

## AuthRedirect

`AppRouter` menambahkan `AuthRedirect` otomatis bila `SessionController`
terdaftar:

- Belum masuk di route lain: diarahkan ke `/sign-in`.
- Belum masuk di `/sign-in`: dibiarkan.
- Sudah masuk di `/sign-in`: diarahkan ke `/`.
- Sudah masuk di route lain: dibiarkan.

Status `unknown` diperlakukan sebagai belum masuk. Restorasi sesi harus selesai
sebelum UI pertama tampil, atau aplikasi akan singgah di `/sign-in` lebih dulu.

## Refresh saat sesi berubah

`SessionRefreshListenable` meneruskan `SessionController.changes` ke
`refreshListenable` milik `GoRouter`. Saat pengguna masuk atau keluar,
go_router mengevaluasi ulang redirect tanpa membangun ulang seluruh aplikasi.
Listenable ini dibuang bersama router di `AppRouter.dispose`.

## Guard khusus

Tambahkan guard lewat konstruktor `AppRouter`:

```dart
final router = AppRouter(
  registry: registry,
  guards: <RouteGuard>[
    MaintenanceGuard(registry.read<Env>()),
    RoleGuard(requiredRole: 'admin'),
  ],
);
```

Guard tambahan berjalan setelah guard bawaan. Untuk mengganti perilaku
sign-in, ganti `AuthRedirect` di `AppRouter` atau sediakan guard yang menangani
lokasi tersebut sebelum guard bawaan.
