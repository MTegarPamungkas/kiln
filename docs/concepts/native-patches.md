# Native patches

Extensions can modify platform files through manifest blocks:

- Android: permissions, URL schemes, App Links, broadcast receivers,
  `allowBackup`, activity host, minSdk, compileSdk.
- iOS: Info.plist, entitlements, associated domains, URL schemes, Podfile flags,
  URL handling in AppDelegate.
- macOS: entitlements in DebugProfile and Release, URL schemes in Info.plist.
- Web: markers in `index.html`.

Patches are idempotent, have stable ids, and are recorded in the lockfile. A
patch used by more than one extension uses reference counting; the patch is only
reverted when the last owner is removed.

Patches are applied only when the platform folder exists in the project.
`kiln doctor` reports patches that are missing from the lockfile.

The `conditional` block adds patches that are active only when specific prompt
answers match. Answers are stored in `kiln.yaml`, so `kiln remove` and
`kiln upgrade` reconstruct the same patches. A scalar condition matches a value
inside a multi-select answer, which lets permission kinds add their own native
setups.
