# Product decisions: remote-config cadence, migration limits, preference durability

Date: 2026-11-22 (Asia/Jakarta). Resolves the three open "design decision" items
from [status](current-status.md): K16, K17, K27. No commit or deployment was
made. The guiding rule was "what makes the SDK better long-term": a small,
dependency-free behaviour change where it removes a footgun, and a documented
boundary where a change would add cost or risk without paying it back.

## K16 - remote config refresh cadence

**Decision: app-owned cadence, with an opt-out resume refresh.** `fetchInterval`
was advisory and nothing reacted to it. The two heavier alternatives (a free-
running in-app timer, or OS background work through WorkManager/BGTaskScheduler)
each cost battery or a new native dependency for behaviour most apps do not need.

What ships:

- `RemoteConfigModule` listens to `Lifecycle` and refreshes when the app resumes
  **after it was backgrounded for at least `fetchInterval`** (and `fetchInterval`
  has passed since the last successful refresh). Both checks use the injected
  `Clock`, so it is deterministic in tests.
- Refreshes are single-flight: a resume that arrives while a refresh is in
  flight does not start a second one. A failed refresh keeps the active snapshot
  and simply retries on the next resume.
- `RemoteConfigConfig.refreshOnResume` (default `true`) turns the behaviour off
  for apps that want full control. No OS background scheduling is added, so the
  native manifest is unchanged.

The `fetchInterval` doc comment now states it is a minimum resume gap, not a
background timer. Evidence: module tests for "refresh after the interval",
"no refresh too soon", and "no refresh when disabled".

## K17 - migration/import recovery limits

**Decision: document the boundary, do not change the algorithm.** Recovery is
already strong (per-step checkpoints, crash rollback, import journal, real
multi-process tests). The two remaining limits — a full snapshot per migration
step on a large store, and no detection of an unrelated writer inside an
interrupted import — only bite at scales this SDK does not target yet, and every
fix (incremental deltas, author tags) adds a new failure mode for a benefit that
is unproven on real data.

Recorded as a known limit rather than a defect. If a real app hits multi-tens-of-
MB stores during a migration, incremental checkpoints become a new finding with
real measurements behind it.

## K27 - preference durability reporting

**Decision: report durability, keep the session behaviour.** Theme and locale
controllers already applied a choice immediately and swallowed storage failures,
so `gate.setThemeMode`/`setLocale` returned a bare success even when the choice
would vanish on restart. The two prior options were worse: a silent success hides
the problem, and an `Err` would force every caller to handle a case that is not
really an error (the choice did apply).

What ships:

- New core type `PersistOutcome { persisted, sessionOnly, notConfigured }` with
  `isPersisted`.
- `ThemeModeController.setMode` and `LocaleController.setLocale`/
  `followSystem` return `PersistOutcome`; the choice still applies for the
  session regardless of the outcome.
- `gate.setThemeMode`, `gate.setLocale`, `gate.followSystemLocale` now return
  `Result<PersistOutcome>`. Existing callers that ignore the value keep working;
  callers that care can show a warning when `isPersisted` is false.
- Shared ARB copy `preferenceNotSaved` (en/id) covers the `sessionOnly` case for
  both theme and locale, so the UI stays consistent.

Evidence: controller tests for persisted/sessionOnly/notConfigured, gate tests
asserting the outcome type, and the rendered `theme`/`l10n` suites.

## Incidental fix

While regenerating the `l10n` suite, its "friendly message for every known code"
test failed on `network.deadline_exceeded`: K19 added that code to
`FailureCode.known` but the localized map was never updated. It now maps to the
network message, so the invariant test passes again.

## Verification

`dart analyze` clean; docs (100 files), metadata and versions consistent; every
extension golden matches; bundle/registry/catalog checks pass; `kiln_core` 191,
`kiln_extension_sdk` 183, `kiln_cli` 160 tests pass; the rendered `remote_config`,
`theme` and `l10n` suites analyzed and passed; the composed fixture analyzed and
passed.
