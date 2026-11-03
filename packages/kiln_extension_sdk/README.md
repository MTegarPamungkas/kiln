# kiln_extension_sdk

Mesin di balik `kiln add` dan `kiln remove`.

- `manifest/` — model, validator, prompt, compatibility, contribution.
- `resolver/` — capability index, dependency graph, plan, conflict.
- `renderer/` — Mason bundle, template vars, collision, hook policy.
- `installer/` — lockfile, pubspec, codegen, transaction, ownership, patch
  native, verifier.
- `migrator/` — migration model, loader, runner.

```dart
final installer = ExtensionInstaller(
  projectRoot: project,
  available: bundledExtensions,
);
final result = await installer.add(requested: ['dio']);
```

Semua perubahan file berjalan di dalam transaksi dengan jurnal dan rollback.

## Manifest native Android

Selain permission dan URL scheme, extension bisa mendeklarasikan broadcast
`receiver` yang ditambahkan ke `AndroidManifest.xml` saat install:

```yaml
android:
  permissions:
    - android.permission.RECEIVE_BOOT_COMPLETED
  receivers:
    - name: com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
      exported: false
    - name: com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
      exported: false
      actions:
        - android.intent.action.BOOT_COMPLETED
        - android.intent.action.MY_PACKAGE_REPLACED
```

Receiver ditulis sebelum `</application>` dengan marker `kiln:android.receiver.*`,
sehingga `kiln remove` bisa menghapusnya kembali tanpa menyentuh receiver lain.

### Native kondisional

Native entry bisa bergantung pada jawaban prompt. Semua pasangan nilai di
`when` harus cocok; list dibandingkan per elemen:

```yaml
conditional:
  - when:
      exact_alarms: true
    android:
      permissions:
        - android.permission.SCHEDULE_EXACT_ALARM
```

Jawaban disimpan di `kiln.yaml`, sehingga `kiln remove` dan `kiln upgrade` bisa
merekonstruksi patch yang sama. Jangan memakai prompt `secret` untuk kondisi.
