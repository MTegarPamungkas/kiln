# Composed extension fixture and log record bounds

Date: 2026-11-21 (Asia/Jakarta). No commit or deployment was made. Closes the
local test work in [status](current-status.md): K12 and K20.

## K12 - composed multi-extension fixture

### Why not all 34 modules in one bootstrap

The official extensions cannot all boot together, and the attempt proved it:

- `ModuleGraph` rejects a capability provided by more than one module. Four
  extensions provide `auth` (appwrite, firebase, rest_auth, supabase), two
  provide `push_transport`, and two provide a state capability.
- Mutually exclusive alternatives also render the same files. `bloc` and
  `riverpod` both write `lib/features/notes/...` (domain, data, presentation and
  the notes page test), so `kiln add`'s file rendering has to pick one.

That is by design, not a defect: the category flag keeps alternatives apart.
K12 therefore verifies a **maximal compatible set** in one app and leaves one-at-a
-time checks to `verify_extensions`.

### The fixture

`tool/verify_composed.dart`:

1. Renders the app and a reviewed 27-module set: one representative per
   capability (`appwrite` for auth, `appwrite_push` for a push transport, `bloc`
   for state), plus every non-exclusive extension that composes.
2. Generates `lib/extensions/extensions.g.dart` for exactly that set, so a drift
   in the reviewed selection fails the generated test instead of silently
   changing the app.
3. Writes the merged pubspec (highest caret wins for the only duplicate
   constraint, `shared_preferences ^2.3.0`/`^2.5.6`; `kiln_core` is path
   overridden), then `flutter pub get`, `flutter analyze`, and a generated test
   suite.
4. Fails on a path collision inside the selected set and reports duplicate
   capabilities across all extensions so the exclusion list stays explicit.

The generated suite checks:

- the exact reviewed module ids and count (27),
- unique ids and unique capability providers,
- 25 randomized input orders where every required capability provider precedes
  its consumer through `ModuleGraph.resolve()`,
- registration in a resolved random order (with the host services `KilnBootstrap`
  normally registers: slots, session, consent, lifecycle, clock, support, gate)
  exposes `TokenProvider`, `AccountManagement`, `AuthRepository`, `Storage`,
  `LocalDatabase`, `RemoteDatabase`, `FileStorage`, `HttpClient` and `AppLogger`.

### Evidence

- `dart run tool/verify_composed.dart --analyze --test`: rendered 27 modules from
  34 extensions, `flutter analyze` reported no issues (74.9 s), and the 3
  generated tests passed.
- `tool/verify_extensions.dart --test` and `tool/check_metadata.dart` still cover
  every extension individually and its manifest/module parity.
- CI's extension job now also runs
  `dart run tool/verify_composed.dart --analyze --test`.
- The CLI suite's integration-heavy setup fixture exceeded the default
  30-second timeout once the regenerated bundles were used, so
  `packages/kiln_cli/dart_test.yaml` now allows two minutes per test. The full
  160-test CLI suite passes.

`flutter analyze` rewrites `analysis_options.yaml` in the fixture ("Upgrading
analysis_options.yaml to exclude build and platform directories"); that is
Flutter's analyzer adding its standard build exclusions in the temp app, not a
project change.

## K20 - per-record size cap

`LimitedSink` now wraps every sink before redaction is chosen:

- message, error, stack trace and every data string are capped at
  `LoggerConfig.maxRecordTextLength` (16384 by default), keeping the prefix and a
  `...[+N chars]` suffix,
- structured data is limited to 12 nested levels and 200 entries,
- cycles are replaced with a marker instead of followed,
- the cap applies with redaction on or off; disabling redaction for local
  debugging no longer permits an unbounded record,
- `LoggerConfig.validate()` rejects a non-positive cap.

Tests: `record_size_limit_test.dart` covers string/depth/entry/cycle bounds, sink
delegation, and a module-level case with `redactionEnabled: false` whose stored
memory record stays within 64 characters; `logger_config_test.dart` covers the
invalid cap. The rendered logger fixture passed analysis and its whole suite.

## Reproduction

```sh
dart run tool/verify_composed.dart --analyze --test
dart run tool/verify_extensions.dart --only logger --analyze --test
```

## Remaining

- Alternative auth/state/notification extensions are covered one at a time, not
  in one bootstrap; they cannot coexist by design.
- A log retention policy is still optional.
