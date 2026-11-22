# Documentation

Kiln documentation, grouped by what you are trying to do.

## Start here

- [Getting started](getting-started.md) — install, create your first app, add an
  extension, and run the tests.
- [Status](audit/current-status.md) — the one-page answer to what is done, what
  is left (and what it needs), plus the special notes and every K01–K33 row.
- [Architecture](architecture.md) — how contracts, the registry, modules, slots,
  and the Gate fit together.
- [Repository layout](folder-structure.md) — where packages, extensions, tooling
  and generated artifacts live.
- [Roadmap](roadmap.md) — what is built and what is still planned.
- [Findings](audit/findings.md) — the K01–K33 definitions and their dated
  implementation paragraphs.

Dated evidence reports, one per acceptance pass (read them only when you need
the raw evidence; the status page links the relevant one):

- [Android/web auth](audit/android-web-auth-2026-11-19.md)
- [Appwrite services and Android push](audit/appwrite-services-push-2026-11-20.md)
- [Push routing on a physical phone](audit/appwrite-push-routing-2026-11-20.md)
- [Late-initialization fencing](audit/late-init-fencing-2026-11-20.md)
- [Cross-handle durability](audit/cross-handle-durability-2026-11-20.md)
- [Media dimension limits](audit/media-dimension-limits-2026-11-20.md)
- [Dio + HTTP cache composition](audit/dio-cache-composition-2026-11-20.md)

## API reference

- [Core runtime](reference/core-runtime.md) — bootstrap, registry, modules, lifecycle, support, slots, session, privacy.
- [Gate](reference/gate.md) — every typed verb and the one-call Result rule.
- [Contracts](reference/contracts.md) — the public contracts and their methods.
- [Failure codes](reference/failure-codes.md) — stable codes, kinds, cancellation, retry.
- [Testing](reference/testing.md) — test registry, fakes, contract suites, widget harness.
- [Packages](reference/packages.md) — what each workspace package owns.

## Concepts

- [Contracts and capabilities](concepts/contracts-and-capabilities.md)
- [Contract behavior](concepts/contract-behavior.md)
- [Compatibility](concepts/compatibility.md)
- [Security model](concepts/security-model.md)
- [Slots](concepts/slots.md)
- [Native patches](concepts/native-patches.md)
- [Lockfile and ownership](concepts/lockfile-and-ownership.md)
- [Transactions and rollback](concepts/transactions-and-rollback.md)

## Guides

- [Configure installed extensions](guides/configure-extensions.md)
- [Set up Appwrite](guides/setup-appwrite.md)
- [Set up flavors and env](guides/setup-flavors-and-env.md)
- [Add offline support](guides/add-offline-support.md)
- [Push notifications](guides/push-notifications.md)
- [Swap a backend](guides/swap-backend.md)
- [Migrate bloc to riverpod](guides/migrate-bloc-to-riverpod.md)
- [Kotlin Gradle Plugin warning](guides/android-kotlin-plugin-warning.md)

## Authoring and shipping extensions

- [Write an extension](extensions/writing-an-extension.md)
- [Extension manifest reference](extension-manifest.md)
- [Support and device reporting](extensions/support-and-devices.md)
- [Testing extensions](extensions/testing-extensions.md)
- [Publishing to the registry](extensions/publishing.md)
- [Trust tiers](extensions/trust-tiers.md)
- [Bundled catalog](extensions/catalog.md) (generated)

## Reference

- [CLI command reference](cli/reference.md)
- [Target repository layout](folder-structure.md)
- [Workspace packages](reference/packages.md)

## Architecture decision records

- [ADR 0001 — Never edit user code](adr/0001-never-edit-user-code.md)
- [ADR 0002 — Capabilities, not IDs](adr/0002-capabilities-not-ids.md)
- [ADR 0003 — Hooks and trust](adr/0003-hooks-and-trust.md)
- [ADR 0004 — Transactions and journal](adr/0004-transactions-and-journal.md)
- [ADR 0005 — Checksums and registry](adr/0005-checksums-and-registry.md)
