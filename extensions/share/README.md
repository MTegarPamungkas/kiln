# share

Native share sheet for text, links, and files.

- `ShareService.share()` opens the platform share sheet.
- Shares plain text, a subject, and/or one or more files.
- Returns `shared`, `dismissed`, or `unavailable`.
- Supports an optional origin rectangle for iPad/macOS popovers.

```bash
kiln add share
```

## Runtime support

This extension reports readiness through `SupportRegistry`. The share sheet is
available on Android, iOS, macOS, web, and Windows; Linux is excluded because
file sharing is not implemented by the platform plugin.

See [support and devices](../../docs/extensions/support-and-devices.md).
