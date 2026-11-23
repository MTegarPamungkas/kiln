# Kiln SDK development audit

**Date** 2026-11-23 · **Source baseline** `fbb6c96`

> This report records observations at the source baseline. Current
> implementation status and changelog links are in the
> [audit backlog](current-status.md).

Kiln's strongest product path is a Flutter app that owns its UI and generated
source, calls stable contracts through `Gate`, and can replace providers
without rewriting feature code. The next milestone should make that path
reliable from project creation through install, configuration, upgrade, and
recovery. The bundled path is substantially more complete than the registry
path. A fresh app already exercises that difference because `kiln create`
installs `l10n` automatically.

This audit covers the six packages, the 34-extension catalog, generated apps,
and release tooling. N9–N15 continue the [independent review](independent-review-2026-11-23.md).
The device-specific evidence and remaining work from K01–K33 are tracked in
[internal audit status](current-status.md).

## Package and workflow review

| Area | What is in place | Development priority |
| --- | --- | --- |
| `kiln_core` | Dependency-ordered bootstrap, scoped registry, typed support and failures, session/consent, and vendor-neutral interfaces | Specify the differences between installed, registered, supported, and ready. Test filtered providers, dependent readiness, and concurrent disposal at the public entry points (N1, N7). |
| `kiln_extension_sdk` | Manifests, capability and slot resolution, rendering, file ownership, native patches, migrations, journals | Make recovery dependable before splitting installer code. Keep rollback state discoverable and reject incomplete snapshots before applying any restore (N6, N8). Preserve legacy lockfile semantics and reject unsupported future formats (N14). |
| `kiln_cli` | Scaffolding, bundled add, interactive setup, doctor, repair, upgrade, rollback, and store commands | Give install and maintenance commands a shared view of installed extension metadata. Validate plans before touching a new project and surface compatibility issues before fetching or applying a candidate (N9, N11, N13). |
| `kiln_store` | Registry index, version selection, checksum verification, isolated local cache, and offline retrieval | Make release artifacts immutable by version, capture the identity of installed archives, and verify the same lifecycle online and offline (N12). |
| `kiln_testing` | Reusable fixtures, fakes, widget harness, and contract suites | Label which tests cover a fake, a production adapter through an injected driver, or a live service/device. Add compatibility tests across providers where behavior is supposed to match. |
| `kiln_lints` | Five opt-in rules, with some feature-layer checks exposed by doctor | Keep doctor checks covered on generated projects. Treat plugin lints as opt-in until their analyzer integration can run reliably in generated projects and on Windows paths with spaces. |
| Templates and examples | Minimal and starter apps, multiple state and backend options, sample compositions | Run the same documented journey against a freshly generated app. Include an existing customized project so repair, upgrade, and rollback preserve its edits according to the ownership policy. |
| Documentation site | Content generation indexes Markdown and extension manifests, and the production build succeeds | The build reports a 1.69 MB minified main JavaScript chunk (536 KB gzip). Measure first-load performance and split documentation content by route if it gets in the way of onboarding. |
| CI and release | Package tests, rendered extension checks, one composed fixture, separate HTTP integration, registry and catalog drift checks | Add Windows verification for the installer and compiled CLI, an app built from the released distribution (N15), and a versioned compatibility matrix. Current workflows shown here use Ubuntu and Flutter stable. |

Sources for the package boundaries and user workflow are the
[architecture](../architecture.md), [CLI reference](../cli/reference.md),
[ownership policy](../concepts/lockfile-and-ownership.md),
[lint README](../../packages/kiln_lints/README.md), [CI](../../.github/workflows/ci.yaml),
and [nightly smoke workflow](../../.github/workflows/smoke.yaml).

## Additional findings

### N9 · Registry install cannot resolve a normal generated project

**Priority** High · **Evidence** CLI reproduction against the local registry

Create a temporary project with `kiln create audit_app --platforms android
--no-pub --yes --core-path <checkout>/packages/kiln_core`. Configure the
repository's local `registry/` and run
`kiln store install dio --dry-run --yes --answer base_url=https://example.invalid`.
The resolver rejects the already-installed `l10n`. Store install hands the
installer a catalog containing only the fetched extension. The resolver
requires metadata for every installed ID and for providers of hard
dependencies. The existing store install test uses an empty project, so it
does not exercise this path. [Create](../../packages/kiln_cli/lib/src/commands/create_command.dart)
· [Store install](../../packages/kiln_cli/lib/src/commands/store_command.dart)
· [Resolver](../../packages/kiln_extension_sdk/lib/src/resolver/extension_resolver.dart)
· [Store tests](../../packages/kiln_cli/test/commands/store_command_test.dart)

The rest of the lifecycle has the same catalog boundary. `setup`, `repair`,
and `doctor` look up bundled metadata. Registry upgrade combines the candidate
with the bundled catalog, which still leaves other registry-only IDs
unresolved. The lockfile stores a source enum, version, and file hashes; it
does not carry the registry identity or archive digest. Simply appending the
bundled catalog can unblock the default app, but a shared catalog keyed by the
locked source and version is needed for mixed-source projects.
[Setup](../../packages/kiln_cli/lib/src/commands/setup_command.dart)
· [Repair](../../packages/kiln_cli/lib/src/commands/repair_command.dart)
· [Doctor](../../packages/kiln_cli/lib/src/commands/doctor_command.dart)
· [Upgrade](../../packages/kiln_cli/lib/src/commands/upgrade_command.dart)
· [Lockfile](../../packages/kiln_extension_sdk/lib/src/installer/lockfile.dart)

**Acceptance.** Generate an app with bundled `l10n`, install a registry-only
extension with a capability dependency, configure it, run doctor, upgrade it,
and roll it back. Repeat with a warm offline cache and verify that a missing
locked artifact produces a clear diagnostic. When an installed provider and
the bundled catalog disagree, resolve against the installed version.

### N10 · Native Appwrite push declares a generic auth dependency

**Priority** High for native push · **Evidence** CLI planning and bootstrap
reproductions

`kiln add rest_auth appwrite_push_native --dry-run` accepts the combination
with a valid `base_url` answer. The push manifest and module require `auth`,
which REST auth provides. Push registration then reads `appwrite.Client`
unconditionally. Among those two providers, only Appwrite registers that
client. Bootstrap calls `register()` before the support probe, so readiness
checks cannot handle the missing client. A Flutter test using the generated
push module and a synthetic generic-auth module reproduced the missing-client
`StateError` during Android bootstrap. No broker was contacted. The composed fixture selects Appwrite
and FCM push and does not exercise this incompatible pair.
[Native push manifest](../../extensions/appwrite_push_native/extension.yaml)
· [Push module](../../extensions/appwrite_push_native/brick/__brick__/lib/extensions/appwrite_push_native/appwrite_push_native_module.dart)
· [Appwrite module](../../extensions/appwrite/brick/__brick__/lib/extensions/appwrite/appwrite_module.dart)
· [Bootstrap](../../packages/kiln_core/lib/src/runtime/bootstrap.dart)

**Acceptance.** Express the backing service that the module actually consumes
and keep manifest and runtime requirements aligned. A project with generic
REST or Firebase auth gets a conflict with a remedy before any writes. An
Appwrite project keeps the shared signed-in client and passes push delivery
checks on its supported paths. Preserve a typed diagnostic for custom
composition that bypasses the CLI.

### N11 · Commands apply different compatibility rules

**Priority** High for registry distribution · **Evidence** Local registry
reproduction and call-site inspection

A fixture extension declaring Dart and Flutter `>=99.0.0` passed
`store install --dry-run` against a local registry. Automatic store install
and upgrade pass the lockfile's core version as the resolver's Kiln version
and omit Dart. Explicit `store install --version` bypasses that resolver.
The resolver has no Flutter input. Doctor checks the running CLI and Dart but
omits Flutter. The extension resolver handles dependencies and slots without a
target-platform argument, so the existing platform diagnostics are mainly
doctor and runtime checks. [Store](../../packages/kiln_cli/lib/src/commands/store_command.dart)
· [Upgrade](../../packages/kiln_cli/lib/src/commands/upgrade_command.dart)
· [Version resolver](../../packages/kiln_store/lib/src/version_resolver.dart)
· [Compatibility model](../../packages/kiln_extension_sdk/lib/src/manifest/compatibility.dart)

**Acceptance.** Establish what `compatibility.kiln` means before extending it.
If CLI and core can move independently, represent their constraints
separately. Use the same compatibility decision for bundled and registry
candidates, including an explicit version. Prefer a compatible older version
for automatic selection. Explain which target platforms remain usable when an
extension is optional, and surface an actionable error when an extension
supports none of the project's targets. Validate under the declared minimum
Flutter/Dart pair as well as the release pair. The baseline workspace and core
already require Dart `^3.13.0`, while current registry entries advertise an
extension-level floor of `>=3.9.0`. Explain the effective project minimum.

### N12 · Registry content can change under an existing version

**Priority** High before treating the registry as a release channel · **Evidence**
Git comparison and release tooling inspection

A comparison of `registry/index.json` between `64ff363` and `fbb6c96` shows
32 extension/version entries present in both commits with different SHA-256
values. The registry generator republishes with `force: true`. The checksum
verifies bytes against the selected index, so different index revisions can
each accept different bytes for the same extension version. An upgrade
selector that requires a greater version cannot deliver those changes to an
app already at that version. Determine which versions were publicly released
before correcting history. [Generator](../../tool/registry.dart)
· [Publisher](../../packages/kiln_store/lib/src/publisher.dart)
· [Offline cache](../../packages/kiln_store/lib/src/offline_mode.dart)
· [Version checker](../../tool/check_versions.dart)

**Acceptance.** Rebuild the same release input twice and compare artifact
digests. Fail release checks when any already-published version changes.
Ship changed content under a new version. Pin the generated app's core and
testing packages to a verified release revision (N2), and record enough archive
provenance to reinstall the same version. Apply retirement policy to legacy
URLs before removing archived files (N5).

### N13 · Create can fail after leaving a project scaffold

**Priority** Medium · **Evidence** CLI reproduction

In a temporary location, `kiln create conflict_app --with appwrite,rest_auth
--platforms android --no-pub --yes --core-path <path>` returned a conflict and
left a scaffold containing `pubspec.yaml`. Create checks extension names
before scaffolding, then resolves capability conflicts and prompts after
writing the base app. A retry at the same path hits the non-empty target
check. The final `flutter pub get` also runs after the installer has committed
the bundled extensions. [Create](../../packages/kiln_cli/lib/src/commands/create_command.dart)

**Acceptance.** Validate requested extensions and required answers before
scaffolding. Define when a new directory becomes visible if Flutter scaffolding,
installation or Pub fails. An ordinary retry should work after a failed first
attempt. Cover `--force` with a pre-existing user file and preserve the
documented overwrite boundaries.

### N14 · Older CLI can accept and rewrite a future lockfile format

**Priority** Medium · **Evidence** Parser round-trip probe

A lockfile with `lock_version: 3` and an extra field parsed successfully.
Serializing the parsed object produced `lock_version: 2` and discarded the
extra field. A mutating command that rewrites the lock could silently lose
metadata from a newer CLI. The registry index reader already rejects unknown
schema versions. [Lockfile](../../packages/kiln_extension_sdk/lib/src/installer/lockfile.dart)
· [Registry index](../../packages/kiln_store/lib/src/registry_index.dart)

**Acceptance.** Continue reading supported v1 and v2 fixtures. A mutating
command fails before writing anything for future formats and tells the user
which CLI version or format is required. Exercise the guard on create-overwrite,
add, repair, setup, and upgrade entry points where they read existing state.

### N15 · The release source bundle omits the workspace root

**Priority** High for release consumers · **Evidence** Extracted release-layout
probe

The tag workflow packages `packages/`, `extensions/`, `bricks/`, `schemas/`,
`tool/`, `registry/`, and `docs/`. It leaves out the root `pubspec.yaml`
and lockfile. The CLI package uses `resolution: workspace`. An archive built
locally with the same path list reproduced Pub's missing workspace root error
when running `dart pub get --offline` in the extracted CLI package. The
workflow attaches the two tarballs and has no CLI binary build step.
[Release workflow](../../.github/workflows/release.yaml)
· [Workspace pubspec](../../pubspec.yaml)
· [CLI pubspec](../../packages/kiln_cli/pubspec.yaml)

**Acceptance.** Make the source archive a usable workspace or provide a
standalone CLI artifact for supported hosts. In CI, extract the exact
artifact, resolve dependencies and run `kiln version` and `kiln create`
outside the checkout. Use this test to catch ref and registry regressions
before attaching release artifacts.

## Where to develop the extension catalog

| Extension group | Manifest inventory | Next useful proof or feature |
| --- | --- | --- |
| Auth, backend and push | `rest_auth`, `supabase`, `firebase`, `appwrite`, `social_login`, `biometric`, `appwrite_push`, `appwrite_push_native` | Fix the native push composition mismatch and resolve Appwrite FCM provider routing. Run the same query, missing-record, watch, and logout cases across backend adapters. Add pagination to providers when they satisfy the existing optional contract. Keep iOS and real Google/Apple acceptance as separate evidence. |
| Network and data | `dio`, `http_retry`, `http_cache`, `storage`, `secure_storage`, `local_db` | Preserve the passing loopback composition. Extend the matrix to provider changes and file-backed upgrades. Run real Keychain reinstall separately and use measured app data size to decide when local migration checkpointing is needed. |
| Navigation, UI and state | `go_router`, `deep_link`, `theme`, `l10n`, `flavors`, `bloc`, `riverpod` | Run a real app fixture for each state implementation and exercise cold-launch links and notification routing. Add a generated-file ownership test for swapping state management with customized feature code and ARB files. |
| Device integration | `connectivity`, `permission`, `notifications`, `image_picker`, `geolocation`, `share`, `calendar` | Record platform and device acceptance independently. Prioritize iOS taps after termination, HEIC and picker, geolocation timing, and custom-scheme links. Distinguish skipped runtime modules from native build failures. |
| Configuration, telemetry and tooling | `logger`, `analytics`, `crash_report`, `remote_config`, `env`, `codegen` | Preserve consent and late-result behavior during upgrades. Verify codegen from a release artifact with its declared hook policy. The current codegen manifest installs both generators, while phase 7 of the roadmap still describes a picker. |

The [generated catalog](../extensions/catalog.md) describes declared platform
support. The [behavior specification](../concepts/contract-behavior.md) defines
portable operations. The [status report](current-status.md) records live
acceptance on specific environments and devices.

## Development order

1. **Protect existing apps.** Start with N6 and N8 in the transaction layer,
   then N14 at lockfile read/write boundaries. Reuse the cross-process test to
   cover interruptions during commit. Add a Windows job for this path.
2. **Make composition trustworthy.** Fix N1 and N10 together in terms of the
   distinction between declared and available capabilities. Add the concurrent
   disposal regression in N7. Cover an invalid provider pairing and valid
   alternatives from the generated app entry point.
3. **Make the lifecycle work across sources.** Fix the default registry install
   in N9, then carry exact installed metadata through setup, doctor, repair,
   upgrade, and rollback. Apply N11 before publishing the same improvements as
   a supported registry workflow. Stage N13's create changes around plan
   validation and a failure-safe scaffold handoff.
4. **Establish a repeatable release.** Fix the archive in N15, enforce immutable versions
   in N12, and pin the generated dependencies in N2. Verify a CLI built from the release, a clean app with no checkout, an older
   project upgraded in place, and an offline reinstall from locked artifacts.
   Document the supported toolchain and add artifact version checks to CI.
5. **Expand the offered capabilities.** Use verified consumer demand to choose
   the next provider feature. The existing pagination contract and the
   Appwrite push paths already have product direction and explicit acceptance
   gaps. Correct roadmap and compatibility pages as their implementations land.

A release candidate should pass one continuous workflow in an isolated fixture:
`create → add bundled → install from registry → setup → doctor → analyze/test →
upgrade → rollback`. Include an intentional compatibility failure and an
interrupted commit. Verify that a user-edited file and untouched project files
survive according to the ownership policy.

## Verification

| Check | Result |
| --- | --- |
| Four package suites from the independent review | 630 passing on the final runs. The snapshot test flake is documented in that review. |
| `kiln_testing` / `kiln_lints` | 83 / 13 passed. |
| Composed HTTP integration | Analyzer passed and six loopback integration tests passed. |
| Composed app fixture | 27 modules analyzed successfully and all three composition tests passed. |
| Rendered extension fixtures | All 34 extension fixtures passed Flutter analysis and their test suites. The runs used 15, 9, and 10 fixtures per batch. |
| Catalog, manifest/runtime metadata, archive, and docs checks | Passed during the independent review. The registry check confirms reproducibility against the supplied index and archives from this checkout. |
| Store, compatibility, create, and lockfile probes | Executed with disposable local projects and a local registry. |
| Native push composition | CLI accepted the pair. A generated-module test reproduced the bootstrap error with a generic auth provider. |
| Documentation site | Content generation and production build passed. Vite reported a large main chunk. |
| Packaged CLI resolution | Confirmed the missing workspace in the release layout. |

Local checks ran on Windows with Flutter 3.47.9 and Dart 3.13.7. The audit
uses source inspection, sample projects, and local test fixtures.
Provider credentials, physical-device tests, and platform signing were outside
this pass. Existing device evidence is linked above.
