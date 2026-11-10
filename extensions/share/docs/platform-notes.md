# Platform notes

`ShareService.share` hands content to the platform share sheet and returns an
outcome; the SDK does not render a sheet of its own.

## Content

```dart
final outcome = await gate.shareContent(
  ShareContent(
    text: 'Bali Weekend — Ubud',
    subject: 'My trip',
    files: <ShareFile>[
      ShareFile(path: photoPath, mimeType: 'image/jpeg', name: 'photo.jpg'),
    ],
  ),
  origin: const ShareOrigin(left: 20, top: 40, width: 120, height: 48),
);
```

- At least one of `text`, `subject`, or `files` should carry content.
- `ShareFile.path` must point to a readable local file. Copy an in-memory file
  to a cache/temp path first; the share sheet does not accept raw bytes.
- `mimeType` helps Android choose targets; it is optional.
- `origin` anchors the iPad/macOS popover. It is ignored on phones.

## Outcomes

| Outcome | Meaning |
| --- | --- |
| `shared` | The user completed the share sheet |
| `dismissed` | The user closed the sheet |
| `unavailable` | The platform/plugin could not provide a share result |

`Ok(ShareOutcome.dismissed)` is not an error. Some platforms cannot report a
result, so they return `unavailable` even when the sheet opened.

## Platforms

Android, iOS, macOS, web, and Windows are supported. Linux is excluded because
the plugin does not implement file sharing there; the extension reports
`unsupportedPlatform` and does not register on Linux.

## Testing

Use a fake `ShareService` and assert the app's outcome handling. Native sheet
behavior, file readability, and iPad popover placement need manual device
testing.
