# Image picker

`MediaPicker.pickImage()` mengembalikan `PickedImage?`; null berarti user
membatalkan. Semua kegagalan dilempar sebagai `Failure`.

```dart
final picker = registry.read<MediaPicker>();

final image = await picker.pickImage(
  source: MediaSource.camera,
  maxWidth: 1024,
  maxHeight: 1024,
  imageQuality: 80,
);

if (image != null) {
  print('${image.name} — ${image.readableSize}');
}
```

## Konfigurasi

Prompt `max_bytes` dan `allowed_types` dirender ke `MediaPickerConfig.defaults`.

- `maxWidth`, `maxHeight`, dan `imageQuality` adalah nilai bawaan; argumen
  `pickImage` menimpanya.
- `maxBytes` diperiksa setelah file dibaca.
- `allowedTypes` berisi MIME. Tipe gambar yang tidak ada di daftar ditolak.

## Tipe gambar

Tipe ditentukan dari byte awal: JPEG, PNG, GIF, WebP, HEIC, dan AVIF.
`mimeType` dari plugin hanya dipakai bila byte tidak tersedia, karena plugin
melaporkan tipe yang tidak konsisten di sebagian perangkat.

## Kamera

Bila extension `permission` terpasang dan memasang kind `camera`,
`CameraPermissionPrecheck` meminta izin sebelum kamera dibuka. Bila kontrak
tidak ada atau tidak bisa menjawab, plugin yang menangani izin.

## Daftar isi

- [Alur unggah](upload-flow.md)
- [Catatan platform](platform-notes.md)
