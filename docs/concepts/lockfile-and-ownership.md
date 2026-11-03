# Lockfile dan kepemilikan

`kiln.lock.yaml` mencatat versi, sumber, dependency, file beserta hash SHA-256,
patch native, dan manual step tiap extension.

```yaml
lock_version: 2
core: "0.1.0"
extensions:
  dio:
    version: "0.2.0"
    source: "bundled"
    dependencies: ["dio"]
    files:
      "lib/extensions/dio/dio_module.dart": "sha256:..."
    patches: ["android.permission.INTERNET"]
    manual_steps: []
```

Aturan:

- File tanpa hash (lock lama) dianggap berasal dari sumber tidak diketahui.
- `kiln remove` hanya menghapus file yang hash sekarang sama dengan lock.
- File yang diedit pengguna dilewati; `--force` menghapusnya.
- `kiln doctor` membandingkan hash dan melaporkan file yang berubah.
- `extensions.g.dart` dimiliki Kiln dan disinkronkan dari lockfile.
