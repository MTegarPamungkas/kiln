# Upload flow

`PickedImage` dan `FileUpload` sama-sama tipe dari `kiln_core`, jadi extension
ini tidak mengimpor backend apa pun.

```dart
final picker = registry.read<MediaPicker>();
final adapter = registry.read<PickedImageUploadAdapter>();

final image = await picker.pickImage();
if (image != null) {
  final stored = await adapter.upload(
    image,
    onProgress: (progress) => setState(() => _progress = progress),
    metadata: <String, String>{'source': 'profile'},
  );
  print(stored.url);
}
```

Alurnya:

1. `pickImage` membaca byte dan mendeteksi MIME.
2. `ImageValidator` menolak gambar yang tidak lolos aturan.
3. `PickedImageUploadAdapter` mengirim `FileUpload` ke `FileStorage`.
4. `FileStorage` mengembalikan `StoredFile` berisi path dan URL.

Adapter membutuhkan byte. Di web byte selalu ada; di perangkat asli byte dibaca
saat memilih sehingga unggahan tidak bergantung pada path sementara.
