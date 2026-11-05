# kiln_extension_sdk

The engine behind `kiln add` and `kiln remove`.

- `manifest/` — models, validator, prompts, compatibility, contributions.
- `resolver/` — capability index, dependency graph, plan, conflicts.
- `renderer/` — Mason bundle, template vars, collisions, hook policy.
- `installer/` — lockfile, pubspec, codegen, transaction, ownership, native
  patches, verifier.
- `migrator/` — migration model, loader, runner.

```dart
final installer = ExtensionInstaller(
  projectRoot: project,
  available: bundledExtensions,
);
final result = await installer.add(requested: ['dio']);
```

All file changes run inside a transaction with a journal and rollback.

## Android native manifest

Besides permissions and URL schemes, an extension can declare broadcast
`receiver`s that are added to `AndroidManifest.xml` at install time:

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

Receivers are written before `</application>` with the `kiln:android.receiver.*`
marker, so `kiln remove` can remove them again without touching other receivers.

### Conditional native entries

A native entry can depend on prompt answers. Every value pair in `when` must
match; lists are compared element by element:

```yaml
conditional:
  - when:
      exact_alarms: true
    android:
      permissions:
        - android.permission.SCHEDULE_EXACT_ALARM
```

Answers are stored in `kiln.yaml`, so `kiln remove` and `kiln upgrade` can
reconstruct the same patch. Do not use a `secret` prompt for conditions.
