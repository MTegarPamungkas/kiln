# Deep links

Extension ini menyediakan kontrak `DeepLinks` dari `kiln_core`. Ada dua jenis
tautan yang ditangani:

1. Scheme kustom, misalnya `kiln://profile/42`.
2. Universal link `https://kiln.dev/profile/42` pada Android dan iOS.

Keduanya masuk lewat `app_links`, dinormalkan, disaring, lalu diteruskan ke
aplikasi.

## Alur pemrosesan

```text
app_links -> LinkNormalizer -> LinkAllowlist -> LinkDeduplicator -> links
```

- `LinkNormalizer` menurunkan huruf scheme dan host, menghapus port default,
  merapatkan garis miring ganda, membuang garis miring di akhir path, membuang
  parameter pelacak (`utm_*`, `fbclid`, dan sejenisnya), serta menghapus
  fragment.
- `LinkAllowlist` menerima scheme kustom yang dikonfigurasi dan `https` hanya
  untuk host yang ada di `allowedHosts`. Path prefix dicocokkan per segmen,
  sehingga `/app` menerima `/app/42` tetapi menolak `/application`.
- `LinkDeduplicator` memakai `Clock`, jadi jendela duplikasi dapat diuji dengan
  `FixedClock`.

## Siklus hidup

```dart
final deepLinks = DeviceDeepLinks(
  gateway: SdkAppLinksGateway(),
  config: DeepLinkConfig.defaults,
  clock: registry.read<Clock>(),
);

await deepLinks.start();
final subscription = deepLinks.links.listen(handleLink);

final initial = deepLinks.initialLink;
if (initial != null) {
  handleLink(initial);
}
```

`start()` idempoten. Tautan yang tiba sebelum listener pertama terpasang
disimpan di `PendingLinkBuffer` dan diputar ulang satu kali saat listener
terpasang. Tautan peluncuran hanya tersedia lewat `initialLink`; tautan yang
sama tidak dikirim dua kali karena deduplikasi.

`dispose()` membatalkan langganan gateway, menutup stream, dan tidak
meneruskan tautan baru.

## Error

`mapDeepLinkError` mengubah error plugin menjadi
`Failure(FailureCode.deepLinkUnavailable, kind: deepLink)` dan
`FormatException` menjadi `FailureCode.deepLinkInvalid`. `DeviceDeepLinks`
menyimpan error terakhir di `lastFailure`; tautan yang ditolak allowlist
diabaikan tanpa error.

## Integrasi router

```dart
final subscription = deepLinks.links.listen((link) {
  final route = link.path.isEmpty ? '/' : link.path;
  final query = link.queryParameters;
  router.go(Uri(path: route, queryParameters: query).toString());
});
```

Untuk tautan scheme kustom, segmen pertama menjadi host URI. `kiln://profile/42`
memiliki `host == 'profile'` dan `path == '/42'`, sehingga aplikasi perlu
memetakan host tersebut ke route, misalnya:

```dart
String routeFor(Uri link) {
  if (link.scheme == 'kiln') {
    return '/${link.host}${link.path}';
  }
  return link.path;
}
```

## Konfigurasi

`DeepLinkConfig` menyimpan scheme, host, path prefix, opsi normalisasi, dan
jendela deduplikasi. Ubah opsi normalisasi dengan membuat konfigurasi baru dan
mendaftarkannya ke `Registry`; `DeepLinkModule` memakai
`DeepLinkConfig.defaults` yang dirender dari prompt.
