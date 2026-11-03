# image_picker

Implementasi `MediaPicker` dari `kiln_core` di atas plugin `image_picker`.

- `DeviceMediaPicker` memakai batas dimensi, kualitas, dan ukuran maksimum dari
  prompt.
- `MimeSniffer` menentukan tipe gambar dari byte awal, bukan dari `mimeType`
  plugin.
- `ImageValidator` menolak gambar yang terlalu besar atau tipe yang tidak
  diizinkan dengan `Failure(media.invalid)`.
- `CameraPermissionPrecheck` memeriksa kontrak `Permissions` lebih dahulu agar
  penolakan izin jelas.
- `LostDataRecovery` memulihkan hasil pilihan saat activity Android dihancurkan.
- `PickedImageUploadAdapter` mengubah `PickedImage` menjadi `FileUpload` untuk
  `FileStorage`; adapter hanya didaftarkan bila kontrak itu ada.
- `ImageSourceSheet` dan `AvatarPicker` siap dipakai untuk UI.

Batas platform dan catatan native ada di
[docs/platform-notes.md](docs/platform-notes.md). Alur unggah ada di
[docs/upload-flow.md](docs/upload-flow.md).
