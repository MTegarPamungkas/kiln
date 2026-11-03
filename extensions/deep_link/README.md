# deep_link

Implementasi `DeepLinks` dari `kiln_core` di atas plugin `app_links`.

- `DeviceDeepLinks` menangkap tautan peluncuran setelah `start()` dan
  meneruskan tautan yang masuk ke listener.
- `LinkAllowlist` menolak scheme dan host yang tidak dikonfigurasi, termasuk
  pencocokan path prefix per segmen.
- `LinkNormalizer` menurunkan huruf scheme dan host, merapikan path, membuang
  parameter pelacak, dan menghapus fragment.
- `LinkDeduplicator` mengabaikan tautan yang sama dalam jendela waktu dari
  `Clock`.
- `PendingLinkBuffer` menyimpan tautan yang tiba sebelum listener pertama
  terpasang, lalu memutarnya ulang satu kali.
- `AppLinkBuilder` membangun tautan keluar dengan scheme proyek atau universal
  link.
- Error plugin diubah menjadi `Failure(deep_link, kind: deepLink)` oleh
  `mapDeepLinkError`.

## Cara pasang

```bash
kiln add deep_link
```

Prompt yang tersedia:

| Prompt | Isi | Default |
| --- | --- | --- |
| `scheme` | scheme kustom tanpa `://` | `kiln` |
| `hosts` | host universal link yang diizinkan | `kiln.dev` |
| `path_prefixes` | prefix path yang diizinkan untuk universal link | kosong |

`hosts` dan `path_prefixes` bertipe `multi`, sehingga pilihannya diambil dari
`options` di `extension.yaml`. Tambahkan host atau prefix Anda ke `options`
sebelum menjalankan `kiln add` bila belum tercantum.

## Konfigurasi

Setelan runtime ada di `DeepLinkConfig`. Nilai default dirender dari prompt;
opsi normalisasi dapat diubah lewat konstruktor:

```dart
const config = DeepLinkConfig(
  scheme: 'kiln',
  allowedHosts: <String>['kiln.dev'],
  pathPrefixes: <String>['/app'],
  stripTrackingParameters: true,
  dropFragment: true,
  deduplicationWindow: Duration(seconds: 2),
);
```

## Pemakaian

```dart
final deepLinks = registry.read<DeepLinks>();

final subscription = deepLinks.links.listen((link) {
  router.go(link.path);
});

final initial = deepLinks.initialLink;
if (initial != null) {
  router.go(initial.path);
}
```

`DeepLinkModule.ready` memanggil `start()` secara otomatis saat bootstrap,
sehingga listener boleh dipasang kapan saja: tautan yang tiba lebih dahulu
disimpan dan diputar ulang satu kali.

Tautan peluncuran tidak dikirim ke `links`; baca `initialLink` agar navigasi
tidak terjadi dua kali.

## Batas penting

- Native memakai `url_schemes: [kiln]` dan host `kiln.dev` yang statis di
  `extension.yaml`. Bila prompt `scheme` atau `hosts` diubah, perbarui bagian
  `android` dan `ios` pada manifest lalu pasang ulang agar intent filter dan
  associated domain ikut berubah.
- Hanya scheme kustom yang dikonfigurasi dan `https` yang diterima; `http`
  ditolak.
- Bila `hosts` kosong, seluruh tautan `https` ditolak dan hanya scheme kustom
  yang bekerja.
- Bila `path_prefixes` kosong, semua path pada host yang diizinkan diterima.

Panduan lanjutan:

- [docs/deep-links.md](docs/deep-links.md)
- [docs/universal-links.md](docs/universal-links.md)
- [docs/testing-links.md](docs/testing-links.md)
