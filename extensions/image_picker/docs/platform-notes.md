# Platform notes

## Android

- **Activity destroyed saat memilih.** Android bisa membunuh activity ketika
  kamera terbuka. Panggil `LostDataRecovery.recover()` saat start untuk
  mengambil hasil yang tertinggal.
- **Photo picker.** Android 13 ke atas memakai photo picker sistem sehingga
  tidak butuh izin penyimpanan untuk galeri.
- **Kamera.** Membuka kamera lewat intent tidak membutuhkan izin `CAMERA` bila
  aplikasi tidak mendeklarasikannya. Bila izin itu dideklarasikan, aplikasi
  harus memintanya sendiri; precheck menangani ini lewat kontrak `Permissions`.

## iOS dan macOS

Extension menambahkan `NSPhotoLibraryUsageDescription` dan
`NSCameraUsageDescription` ke `Info.plist`, serta entitlement file dan kamera
untuk macOS. Teks izin bisa diganti di `extension.yaml` sebelum install.

## Web

`XFile.path` berupa blob URL dan tidak bisa dipakai lintas sesi. Selalu unggah
dari `PickedImage.bytes`, bukan dari path. `PickedImageX.toImageProvider`
memakai `MemoryImage`; tanpa byte ia melempar `Failure(media.invalid)`.

## Batas ukuran

Batas diperiksa setelah byte dibaca. Untuk mencegah memori berlebih pada file
sangat besar, pertahankan `max_bytes` yang wajar dan gunakan `maxWidth`,
`maxHeight`, dan `imageQuality` agar plugin mengecilkan gambar sebelum dibaca.
