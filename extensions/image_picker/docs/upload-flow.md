# Upload flow

`PickedImage` and `FileUpload` are both types from `kiln_core`, so this
extension does not import any backend.

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

The flow:

1. `pickImage` reads the bytes and detects the MIME type.
2. `ImageValidator` rejects images that do not pass the rules.
3. `PickedImageUploadAdapter` sends a `FileUpload` to `FileStorage`.
4. `FileStorage` returns a `StoredFile` containing the path and URL.

The adapter needs bytes. On the web the bytes are always available; on native
devices the bytes are read at pick time so the upload does not depend on a
temporary path.
