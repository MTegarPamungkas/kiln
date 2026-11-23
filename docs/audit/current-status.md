# Audit backlog

Updated 2026-11-23. Start with the remaining device and provider acceptance below. Completed
changes are recorded in component and [release changelogs](../../CHANGELOG.md).
Dated test reports live under [evidence](evidence/README.md).

## SDK implementation review

N1–N15 are addressed in the working tree. Completed implementation notes are
in the [release](../../CHANGELOG.md),
[CLI](../../packages/kiln_cli/CHANGELOG.md),
[core](../../packages/kiln_core/CHANGELOG.md),
[installer](../../packages/kiln_extension_sdk/CHANGELOG.md), and
[store](../../packages/kiln_store/CHANGELOG.md) changelogs. The
[initial review](independent-review-2026-11-23.md) and
[development audit](sdk-development-audit-2026-11-23.md) describe the original
baseline and acceptance criteria.

A [verification sweep](evidence/post-audit-sweep-2026-11-23.md) then checked the
remediation against the full catalog. It fixed five stale extension test suites,
a transaction commit that could roll back a verified install, a `repair` command
that discarded lockfile ownership, and four smaller lifecycle defects, and it
replaced the hand-maintained CI matrix with one derived from the checkout.

## Pending acceptance and product decisions

| Area | Next evidence or decision |
| --- | --- |
| CI availability | [Sweep](evidence/post-audit-sweep-2026-11-23.md) · The billing lock is cleared and a manual dispatch confirmed runners execute again, but no workflow has run against this work yet. |
| Biometric and secure storage | [K06/K07](findings.md#k06-and-k07--biometric-and-keychain) · Lockout behavior and iOS Keychain reinstall with a custom namespace. |
| Notifications and media | [K08/K28](findings.md#k08-and-k28--notification-launch-and-media-on-ios) · iOS cold-launch tap, picker, and HEIC. |
| Telemetry | [K09](findings.md#k09--telemetry-consent-on-ios) · Native iOS consent and queued/automatic traffic. |
| Appwrite push | [K23](findings.md#k23--appwrite-push-routing-and-device-delivery) · Resolve FCM provider selection and verify device delivery. |
| Social sign-in | [K25](findings.md#k25--live-social-credential-exchange) · Real Google and Apple token exchange into the selected backend. |
| Location and deep links | [K26/K29](findings.md#k26-and-k29--location-and-deep-links-on-ios) · Native iOS service/permission transitions and custom-scheme routing. |

[Deferred work and documented limits](findings.md#deferred-work-and-limits)
covers storage scale, retry UX, and installer staging.

<details>
<summary>Repository and device-run notes</summary>

- Use Indonesian for chat and progress notes. Use English for code,
  documentation, CLI output, and commits.
- Commit, publish, or deploy only when the owner asks. Preserve local work.
- Keep credentials in memory or in a temporary ignored file and delete that
  file after the run. Keep credentials out of source, documentation, logs,
  and journals.
- Uninstall the test app before reinstalling after a native change. Report
  emulator and physical-device results separately.
- Fixture commands and cleanup procedures are in the [E2E guide](../../tool/e2e/README.md)
  and [device evidence](evidence/README.md). Use the run's
  `.dart_tool/*_ownership.json` to identify removable Appwrite resources.
  Keep the owner's real Google user.

</details>
