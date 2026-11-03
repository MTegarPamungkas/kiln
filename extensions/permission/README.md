# permission

Implementasi `Permissions` dari `kiln_core` di atas `permission_handler`.

- Hanya kind yang dipilih saat install yang aktif; kind lain menghasilkan
  `Failure(configuration)`.
- Status di-cache dan cache dibersihkan saat app kembali dari settings.
- `PermissionFlow` menjalankan status, rationale, request, dan arahan ke
  settings untuk izin permanen.
- `PermissionGroup` meminta beberapa izin sekaligus.
- `PermissionGate`, `PermissionRationaleDialog`, dan `OpenSettingsDialog`
  tersedia untuk UI.

Catatan native: entri manifest Android dan Info.plist iOS harus disesuaikan
dengan kind yang dipilih. `permission_handler` tidak menambahkan entri native
secara otomatis.
