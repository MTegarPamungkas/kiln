# Patch native

Extension dapat mengubah file platform lewat blok manifest:

- Android: permission, URL scheme, App Links, broadcast receiver,
  `allowBackup`, activity host, minSdk.
- iOS: Info.plist, entitlement, associated domain, URL scheme, flag Podfile,
  penanganan URL di AppDelegate.
- macOS: entitlement di DebugProfile dan Release, URL scheme di Info.plist.
- Web: penanda di `index.html`.

Patch bersifat idempoten, punya id stabil, dan dicatat di lockfile. Patch yang
dipakai lebih dari satu extension memakai reference count; patch hanya
dikembalikan saat pemilik terakhir dilepas.

Patch hanya diterapkan bila folder platform ada di proyek. `kiln doctor`
melaporkan patch yang hilang dari lockfile.

Blok `conditional` menambahkan patch yang hanya aktif saat jawaban prompt
tertentu cocok. Jawaban disimpan di `kiln.yaml`, jadi `kiln remove` dan
`kiln upgrade` merekonstruksi patch yang sama.
