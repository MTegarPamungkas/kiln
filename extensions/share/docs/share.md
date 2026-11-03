# Share

`share` provides `ShareService` from `kiln_core`.

```dart
final share = registry.read<ShareService>();

final outcome = await share.share(
  ShareContent(
    text: 'Bali Weekend — Ubud',
    subject: 'My trip',
    files: <ShareFile>[
      ShareFile(path: photoPath, mimeType: 'image/jpeg'),
    ],
  ),
  origin: ShareOrigin(left: 20, top: 40, width: 120, height: 48),
);
```

`ShareOutcome` reports whether the user shared, dismissed, or whether the
platform could not provide a result. File sharing is available on Android, iOS,
macOS, web, and Windows; the extension is disabled on Linux.
