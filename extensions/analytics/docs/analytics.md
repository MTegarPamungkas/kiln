# Analytics

`Analytics` mencatat event produk dan mengidentifikasi pengguna. Kontraknya ada
di `kiln_core`; extension ini menyediakan implementasi PostHog.

## Konfigurasi

Nilai awal berasal dari prompt install:

- `api_key`: project API key PostHog. Biarkan kosong untuk mematikan analytics
  tanpa mengubah kode aplikasi.
- `host`: host ingest PostHog, default `https://us.i.posthog.com`.

`AnalyticsConfig` juga mengatur `flushInterval` dan `enabledFlavors`. Default
interval adalah 30 detik dan semua flavor standar diizinkan. Persempit daftar
flavor bila event development tidak boleh terkirim:

```dart
final config = AnalyticsConfig.defaults.copyWith(
  enabledFlavors: const <AppFlavor>{AppFlavor.production},
);
```

Module memakai `NoopAnalytics` bila API key kosong, `enabledFlavors` kosong,
atau `AppFlavor` saat ini tidak ada di daftar. Setup SDK dijalankan dengan
best effort: kegagalan PostHog tidak menghentikan aplikasi.

## Pemakaian

```dart
final analytics = registry.read<Analytics>();

await analytics.capture(
  'project created',
  properties: <String, Object?>{'plan': 'pro', 'seats': 3},
);

await analytics.identify(session.userId, traits: <String, Object?>{
  'role': 'owner',
});
```

`capture`, `identify`, dan `reset` melempar `Failure` bila SDK gagal. Bila
pemanggil tidak ingin menangani kegagalan analytics, bungkus dengan
`Result.guard` atau abaikan kegagalan tersebut; analytics bukan alur utama
aplikasi.

## Identitas sesi

`SessionIdentityListener` sudah didaftarkan dan dijalankan oleh module. Saat
`SessionController` memiliki sesi non-null, listener memanggil `identify`
dengan `userId`; saat sesi menjadi null, listener memanggil `reset`. Listener
tidak pernah melempar error ke alur sign-in.

## Mengganti gateway

Semua akses plugin berada di `AnalyticsGateway`. Implementasi SDK adalah
`SdkPosthogGateway`; test memakai gateway palsu. Untuk vendor lain, ganti
gateway dan `PosthogAnalytics` tanpa mengubah decorator consent maupun PII.

Lihat [event-naming.md](event-naming.md) dan
[privacy-and-consent.md](privacy-and-consent.md).
