# Post-audit verification sweep, 2026-11-23

**Date** 2026-11-23 · **Baseline** `3b26c8b` (working tree) · **Host** Windows,
Flutter 3.47.9, Dart 3.13.7

This pass verified the N1–N15 remediation and swept the full 34-extension
catalog. It found five stale extension test suites, one packaging consequence of
fixing them, four lifecycle defects outside N1–N15, and a CI gap that let all of
it reach `main`. Every fix below is covered by a regression test that was
confirmed to fail before the fix.

## CI had stopped verifying anything

All workflows failed from 2026-11-22 with "account is locked due to a billing
issue". No automated check ran, so the findings below landed unverified.

`extensions.yaml` also carried a hand-maintained matrix of 26 extensions while
the catalog held 34. `appwrite_push`, `appwrite_push_native`, `calendar`,
`codegen`, `crash_report`, `geolocation`, `remote_config`, and `share` were
never tested by CI even with billing healthy. The matrix is now derived from the
checkout by a `discover` job, and `tool/check_workflows.dart` fails when the
matrix is hand-listed again or an extension lacks a manifest, pubspec, or
`test/` directory.

## Red extension suites

All five reproduced locally before the fix and pass after it.

| Suite | Symptom |
| --- | --- |
| `appwrite_push_native/test/manifest_test.dart` | Expected `requires: ['auth']`; the manifest declares `appwrite_client` (N10). |
| `appwrite/test/manifest_test.dart` | `provides` did not list the shared `appwrite_client` capability. |
| `appwrite/test/render_test.dart` | Golden predates `oAuthRedirectUrl`; the brick gained web OAuth support in `fbb6c96`. |
| `remote_config/test/manifest_test.dart` | Expected `optional_requires: ['flavor']`; the manifest also declares `storage`. |
| `remote_config/test/render_test.dart` | Golden predates `cacheTtl` and `refreshOnResume`. |
| `analytics/test/render_test.dart` | Golden predates the session-identity and consent settings added in `fbb6c96`. |
| `deep_link/test/render_test.dart` | Golden predates `customSchemeHosts`, added in `fbb6c96`. |

`remote_config`, `analytics`, and `deep_link` were not in the original report.
The bricks genuinely read `Storage`, `cacheTtl`, the consent/session settings,
and the custom-scheme hosts, so the manifests and bricks are correct and the
tests were stale.

Each extension keeps two golden representations: `test/goldens/rendered.json`
holds the expected SHA-256 per file, and `test/goldens/rendered/**` holds the
bytes compared by `render_test.dart`. `fbb6c96` refreshed `rendered.json` but
left the per-file `.dart.golden` stale. Every regenerated golden was checked
against the committed `rendered.json` hash and matched, which confirms the
golden was wrong rather than the brick.

**Packaging consequence.** `ArchivePacker` packs each extension's own `test/`
directory: 61 of 61 published archives contain one. Fixing a test therefore
changes the archive bytes of an already-published version, and the N12
immutability guard rejects it. The versions were bumped per the documented
policy (`appwrite` 0.3.3, `analytics` 0.1.1, `deep_link` 0.1.2,
`remote_config` 0.1.2, `appwrite_push_native` 0.2.2) and the registry
regenerated. Excluding `test/` from release archives would avoid forcing a
version bump for test-only changes; that is a product decision, because the
extension `test/` suite is currently shipped to consumers.

**Line-ending hazard.** The first regeneration embedded a `CHANGELOG.md` with
CRLF bytes, because the editor wrote that one file with Windows endings while
`.gitattributes` requires LF. The archive then differed from the working tree
and `tool/registry.dart --check` failed with an immutability error even though
the tree was correct. Any hand-edited extension file must be LF before the
registry is regenerated.

## Lifecycle defects

### Prune could roll back a committed install

`Transaction.commit()` caught only `FileSystemException`, but `pruneHistory`
can throw `KilnException` from `RootPath.validateId` for an unusable backup id,
or when `.kiln/backups` is a link. The exception escaped into the installer's
`catch`, which then called `rollback()` on a transaction that had already been
verified and committed. Post-commit bookkeeping is now best effort and catches
both types; the journal stays discoverable so a later `kiln rollback` still
works.

### `kiln repair` discarded ownership metadata

`repair` wrote a fresh lockfile with only `core` and `extensions`, dropping
`owned_dependencies`, `owned_dev_dependencies`, and `owned_flutter_generate`,
and wrote files outside any journal. A later `kiln remove` then lost the trail
of which pubspec entries Kiln had inserted and left them behind. `repair` now
runs inside a `Transaction` and carries the three ownership maps forward.

### Smaller fixes

- `Transaction.commit()` retried the journal-to-history rename on Windows
  sharing violations (error codes 5, 32, 33), matching `Journal.save()`.
- Transaction ids were a bare microsecond timestamp; two transactions starting
  in the same tick could collide and overwrite a recovery record. Ids now add a
  per-process counter, a random suffix, and an on-disk existence probe.
- `create --force` rewrote an existing project without holding that project's
  lock, because the runner only locks the working directory's project. It now
  acquires the target's lock.
- `GetItRegistry.unregister` skipped the disposal gate that every other mutator
  applies, so it could race the owned-disposal pass and the reset.

## Toolchain move to Flutter 3.50.1

CI had been failing before it ever ran a step: every job reported
`runner_id: 0`, no steps, and completed within two seconds. Once the account's
billing lock was cleared, a manual `Drift` dispatch showed the runner executing
again, and the real cause surfaced at `flutter pub get`:

```
Because kiln_testing depends on flutter_test from sdk which depends on
test_api 0.7.14, test_api 0.7.14 is required.
And because test 1.31.1 depends on test_api 0.7.12, test 1.31.1 is forbidden.
Because test >=1.31.2 depends on analyzer >=13.0.0 <15.0.0 ...
So, because kiln_workspace depends on both analyzer ^8.4.0 and test ^1.31.1,
version solving failed.
```

The local SDK was 3.47.9 while CI's `channel: stable` had moved to 3.50.1 /
Dart 3.14.0. Reproducing on 3.50.1 locally produced the identical error. The
constraint chain is not resolvable by upgrading: `custom_lint_builder` 0.8.1 is
still the newest release and pins `analyzer ^8`, while the SDK's `test_api`
requires `analyzer ^14`. Pub resolves a workspace as one unit, so `kiln_lints`
made the whole repository uninstallable.

Fixes:

- `kiln_lints` now resolves outside the workspace with its own `pubspec.lock`
  (analyzer 8), and the root pins `analyzer ^14`. CI runs `dart pub get` for it
  before `dart test`.
- `tool/check_metadata.dart` used `ClassDeclaration.members`, which analyzer 14
  moved to `declaration.body.members`.
- Flutter 3.50 deprecated `package:flutter/material.dart` in favour of
  `package:material_ui`. Migrated the app template, 40 extension brick files,
  76 example files, `kiln_testing`, and 32 `analyze_test.dart` fixture
  pubspecs. `flutter create` on 3.50 already adds `material_ui`, so generated
  applications were correct; only the templates lagged.
- `gen-l10n` still emits `GlobalMaterialLocalizations` from
  `package:flutter_localizations`, which 3.50 deprecated. This is upstream and
  not fixable here, so the generated directory is excluded from analysis in the
  app template.

## Archive scope

`ArchivePacker` shipped each extension's own root `test/` directory, so a
test-only fix changed the archive digest and the N12 guard rejected the
already-published version. Installing reads only `extension.yaml`, `brick/`,
and `docs/` (`registry_support.dart`), so the suite was dead weight. The packer
now skips the root `test/` while still packing `brick/__brick__/test/`, which is
the suite rendered into applications. A regression test asserts both halves.

This changed every archive digest at once, so the registry was regenerated from
an empty index. It now holds 34 versions (one per extension) instead of 65: the
older entries were built by the previous packer and cannot be reproduced, so
their history was dropped rather than republished with mismatched bytes. The
registry has never been hosted, so no consumer depends on those digests.

## Verification

| Check | Result |
| --- | --- |
| Flutter / Dart | 3.50.1 / 3.14.0, `flutter doctor` clean |
| `kiln_core` | 194 passed |
| `kiln_extension_sdk` | 191 passed |
| `kiln_store` | 95 passed |
| `kiln_cli` | 167 passed |
| `kiln_testing` | passed |
| `kiln_lints` | 13 passed (standalone, analyzer 8) |
| Extension suites | 34 of 34 passed |
| `dart analyze` and `flutter analyze` | No issues |
| Lint, bundle, catalog docs, verify, registry, docs, versions, workflows, metadata | All `--check` runs passed |

The `rollback_test` cross-process case failed once and then passed six
consecutive runs, including on a clean tree; it is a pre-existing timing flake
in the child-process handshake, not a regression from this pass.

## Remaining

- The billing lock is cleared, but no workflow has run against this work yet;
  it is all verified locally on the same toolchain CI uses.
- The device and provider acceptance already tracked in the
  [audit backlog](../current-status.md).
