# Rules for rewriting sections of folder-structure.md

## Context

Kiln is a monorepo (CLI + SDK + `kiln_core`) that generates Flutter
applications through "extensions" (an `extension.yaml` manifest + a Mason
brick). The `folder-structure.md` document is the **blueprint for building a
Kiln project from scratch**. Because it is built from scratch, there is no
longer any difference between "already exists" and "new": every file is
treated as one that will be created.

Your task: rewrite ONE section of the document (a specific line range of
`Test AI/kiln/docs/_wip/source.md`) so that:

1. every "new" marker is gone, and
2. **every file and folder in the tree has a short, clear description.**

You do not own the design. Do not add, remove, or move files
(except for the renames in rule 8). Your job is editorial only.

## How to work

1. Read `Test AI/kiln/docs/_wip/source.md` over the line range you are given
   (read_file with start_line and end_line). Also read the contracts in the
   `kiln_core` part of that document (lines 245-316) if you need to understand the
   terminology.
2. Write the result to `Test AI/kiln/docs/_wip/part_<NN>.md` with write_file.
   If the result is too long for a single call, split it into
   `part_<NN>a.md`, `part_<NN>b.md`, and so on, exactly at the boundary between
   sections (do not cut in the middle of a code block).
3. The result contains exactly the assigned range: no extra
   opening or closing sentences and no wrapper. Start at the first line of
   the range, end at its last line.
4. Reply with a short message: the file name you wrote, the line count, and anything
   doubtful. Do not copy the result into the reply.

## Writing rules

1. **Remove the "new" markers**: `# new`, `# new:` (keep the description
   after the colon), `(new)`, `# new in this folder`, `# new, seluruh
   folder`. The word "new" must not remain as a status marker. The `# generate`
   marker becomes part of the description, e.g. `generated from ..., do not edit`.
2. **Every tree line must have a comment.** Every line that uses
   `├─` or `└─` must end with `# description`. There must be no
   file or folder line without a comment (including `lib/`, `test/`, `docs/`,
   `fixtures/`, `widgets/`, `hooks/`, `__brick__/`).
3. **One file or folder per line.** Split lines that carry several
   entries. Example: `├─ a_test.dart, b_test.dart  # new` becomes two lines
   with their own descriptions. `├─ kiln.yaml, kiln.lock.yaml, pubspec.yaml`
   becomes three lines. `├─ fresh_app/, app_with_dio/` becomes two lines.
   The branches (`├─` and `└─`) must stay correct: the last entry in a folder
   uses `└─`, the others `├─`, and the vertical bar `│` is carried through
   correctly for their children.
4. **Description form**: one clause of 3 to 12 words (about 90 characters max),
   with no trailing period, stating *what the file does*, not repeating its name.
   - Bad: `# cache helper`. Good: `# builds a cache key from the URL, query, and Vary header`.
   - Test files: start with `tests ...` and name the main behavior.
     Example: `# tests that a transient failure is retried per the policy`.
   - `*_module.dart`: `registers <what> with the Registry`.
   - `*_gateway.dart`: `wraps <plugin> so it can be faked in tests`.
   - `*_failure_mapper.dart`: `maps <source> errors to Failure`.
   - `*_config.dart`: `typed configuration: <main contents>`.
   - `*_contract_test.dart`: `runs the <name> contract suite from kiln_testing against this implementation`.
   - Folders: describe what they contain, e.g. `# ready-made widgets for this feature`.
   - Do not use filler words such as "helper", "util", "etc.", or
     "various" without context.
5. **The `extension.yaml` line** uses the `# manifest: ...` format and contains the
   important fields already written in its original comment (provides, requires,
   category, exclusive, slot or contributes, prompts, platform). Keep it short,
   about 140 characters max. Drop `(new)` inside it.
6. **The extension-level `test/` block.** Every line
   `├─ test/    # manifest_test, render_test, analyze_test, goldens/rendered/`
   in an extension tree is replaced with exactly the following block (the
   extension tree indentation is the same in every extension):

   ```text
   ├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
   │  ├─ manifest_test.dart                    # ensures extension.yaml is valid against extension.schema.json
   │  ├─ render_test.dart                      # renders the brick to a temp folder, the result must match the golden
   │  ├─ analyze_test.dart                     # the rendered result must pass dart analyze without warnings
   │  └─ goldens/rendered/                     # reference render output for render_test, generated via kiln ext test --update-goldens
   ```

   This applies only to `extensions/<id>/` trees. The standard block in the
   "Conventions" section is handled by someone else; do not touch it if it is outside
   your range.
7. **Structure is preserved.** The order, hierarchy, and number of files match the
   source (after the line splitting in rule 3 and the renames in
   rule 8). Headings, paragraphs, tables, and mermaid diagrams are preserved
   as they are, except for sentences that discuss the status "new", "already present",
   "previous", "now", "moved", or "name unchanged": rewrite
   those sentences as if the project were built from scratch, or delete them if they only
   talk about a comparison with the old condition.
8. **Error mapper naming is unified** across the whole document:
   - `firebase_failures.dart` becomes `firebase_failure_mapper.dart`
   - `supabase_failures.dart` becomes `supabase_failure_mapper.dart`
   - `social_failures.dart` becomes `social_login_failure_mapper.dart`
   - `analytics_failures.dart` becomes `analytics_failure_mapper.dart`
   - the matching test files follow: `<name>_failure_mapper_test.dart`.
   If the replacement leaves two entries with the same name in one folder,
   merge them into a single entry. Delete notes such as "the existing error
   mapper, its name is not changed (see Design decisions)".
9. **Remove references to the old condition.** Example rewrites:
   - `typedef LogSink moved from console_logger.dart together with the sink interface`
     becomes `sink contract and the LogSink typedef`
   - `the existing Biometric facade` becomes
     `Biometric facade: canAuthenticate and authenticate`
   - `the code and message table moved from biometric.dart` becomes
     `plugin error code to FailureCode table with their messages`
   - `(this brick previously had no module)` is deleted
   - `(now through HttpPipeline.use)` becomes `(attached to HttpPipeline)`
   - `moved from src/` is deleted; write only the file's destination.
10. Do not use backticks inside code blocks. Technical terms keep their
    original spelling (Registry, Failure, Clock, Slot, AppLogger, etc.).
11. Comment format: two or more spaces before `#`, one space after it.
    Column alignment is tidied up automatically later, no need to do it by hand.

## Contract vocabulary (for writing test and file descriptions)

`kiln_core` contains: `Storage` (key-value), `SecureStorage`, `HttpClient`,
`HttpMiddleware`, `HttpPipeline`, `HttpCache`, `AuthRepository`, `SocialAuth`,
`SocialLogin`, `AccountManagement` (password reset, email verification, profile
update), `LocalDatabase`, `RemoteDatabase`, `FileStorage`, `NetworkMonitor`,
`Permissions`, `Notifications`, `DeepLinks`, `MediaPicker`, `Analytics`,
`CrashReporter`, `AppLogger`, `Env`, `AppFlavor`, `Failure`, `FailureCode`,
`Result<T>`, `Registry`, `KilnModule`, `SessionController`, `TokenProvider`,
`ConsentController`, `PiiRedactor`, `Clock`, `Debouncer`, `OrderedSlot<T>`,
`Lifecycle`, `KilnBootstrap`.

Slots: `registry` (default), `http.interceptors` (opened by `dio`, items are
`HttpMiddleware`), `router.routes` (opened by `go_router`, items are `AppRoute`),
`app.wrappers` (default in `app_basic`, items are `AppWrapper`).

`kiln_testing` contains a fake per contract, a `*_contract.dart` suite per contract,
and the test harnesses (`test_registry`, `pump_app`, matchers, async helpers).
