## kiln_cli

The CLI only handles interaction: command parsing, prompts, reports, and exit
codes. All installation logic lives in `kiln_extension_sdk`, so every command
stays thin and easy to test.

```text
packages/kiln_cli/
├─ bin/  # kiln executable entry point
│  └─ kiln.dart  # main function that runs the command runner then exits with its code
├─ lib/  # CLI library code used by bin/kiln.dart and test/
│  ├─ kiln_cli.dart  # barrel that exports the kiln_cli public API
│  └─ src/  # internal CLI implementation: commands, infra, and bundles
│     ├─ command_runner.dart  # registers all commands and forwards arguments to the matching command
│     ├─ project_context.dart  # detects a kiln project then reads kiln.yaml and the lockfile
│     ├─ paths.dart  # builds the paths for kiln.yaml, the lockfile, and the ~/.kiln directory
│     ├─ version.dart  # CLI version constant for the version command and the update checker
│     ├─ commands/  # implementation of each CLI subcommand, one file per command
│     │  ├─ create_command.dart  # create command: builds a project from app_basic with the chosen state management
│     │  ├─ add_command.dart  # add command: installs extensions transactionally through the SDK
│     │  ├─ remove_command.dart  # remove command: uninstalls an extension and only deletes files that have not been edited
│     │  ├─ list_command.dart  # list command: shows installed or available extensions
│     │  ├─ doctor_command.dart  # doctor command: checks project health, can fix issues with --fix
│     │  ├─ version_command.dart  # version command: shows the CLI and kiln_core versions
│     │  ├─ command_helpers.dart  # shared options and flow between commands, such as --dry-run and --yes
│     │  ├─ info_command.dart  # info command: shows an extension's provides, requires, platforms, and changelog
│     │  ├─ upgrade_command.dart  # upgrade command: bumps an extension version then runs migrations
│     │  ├─ rollback_command.dart  # rollback command: reverses the last operation from the journal
│     │  ├─ graph_command.dart  # graph command: prints the requires and capability graph as text or mermaid
│     │  ├─ config_command.dart  # config command: configures the registry, mirror, and offline mode
│     │  ├─ cache_command.dart  # cache command: views and clears the registry cache
│     │  ├─ store_command.dart  # store command: searches and views extensions in the registry
│     │  ├─ completion_command.dart  # completion command: prints bash, zsh, and fish autocomplete scripts
│     │  └─ ext/  # kiln ext subcommands: tools for extension authors
│     │     ├─ ext_new_command.dart  # ext new command: creates an extension skeleton with its manifest and brick
│     │     ├─ ext_validate_command.dart  # ext validate command: checks extension.yaml against the schema
│     │     ├─ ext_test_command.dart  # ext test command: runs extension tests, optionally with --update-goldens
│     │     ├─ ext_pack_command.dart  # ext pack command: packs an extension into an archive for the registry
│     │     └─ ext_publish_command.dart  # ext publish command: publishes an extension archive to the registry
│     ├─ infra/  # supporting CLI services: logging, prompts, reports, configuration, and system access
│     │  ├─ kiln_logger.dart  # records leveled logs and progress, honoring --verbose and --quiet
│     │  ├─ prompter.dart  # shows interactive prompts, respects --yes, and detects non-TTY
│     │  ├─ exit_codes.dart  # fixed exit codes for each command outcome, used by CI
│     │  ├─ json_reporter.dart  # reports command results as JSON when --json is active
│     │  ├─ error_presenter.dart  # turns a KilnException into a message along with remediation advice
│     │  ├─ global_config.dart  # typed configuration: registry, mirror, and offline mode from ~/.kiln/config.yaml
│     │  ├─ update_checker.dart  # notifies about a newer CLI version without blocking the command
│     │  ├─ process_runner.dart  # runs external processes such as flutter and dart with controlled output
│     │  └─ file_system.dart  # file system abstraction so commands can be tested without a disk
│     └─ bundles/  # bundles for all extensions, generated from extensions/, do not edit
│        ├─ catalog.g.dart  # catalog of available extensions, generated from extension.yaml, do not edit
│        ├─ app_basic_bundle.dart  # app_basic bundle for create, generated from extensions/app_basic, do not edit
│        └─ <id>_bundle.dart  # per-extension bundle (29 files), generated from extensions/<id>, do not edit
├─ test/  # kiln_cli package tests: command runner, commands, infra, fixtures, and goldens
│  ├─ command_runner_test.dart  # tests argument-to-command mapping and the command runner exit code
│  ├─ commands/  # one test file for each CLI command
│  │  ├─ create_command_test.dart  # tests that create builds a project from app_basic according to the state and platform options
│  │  ├─ add_command_test.dart  # tests that add installs extensions transactionally, including dry-run mode
│  │  ├─ remove_command_test.dart  # tests that remove only deletes files the user has not edited
│  │  ├─ list_command_test.dart  # tests that list shows installed and available extensions, including --json
│  │  ├─ doctor_command_test.dart  # tests that doctor reports changed hashes, missing patches, and leftover journal entries
│  │  ├─ info_command_test.dart  # tests that info shows provides, requires, platforms, and the changelog
│  │  ├─ upgrade_command_test.dart  # tests that upgrade bumps the extension version then runs migrations
│  │  ├─ rollback_command_test.dart  # tests that rollback reverses the last operation based on the journal
│  │  ├─ graph_command_test.dart  # tests that graph prints the requires graph in text and mermaid format
│  │  ├─ config_command_test.dart  # tests that config configures the registry, mirror, and offline mode
│  │  ├─ cache_command_test.dart  # tests that cache shows and clears the registry cache
│  │  ├─ store_command_test.dart  # tests that store searches and displays extensions from the registry
│  │  └─ ext_commands_test.dart  # tests the ext subcommands: new, validate, test, pack, and publish
│  ├─ infra/  # tests for infra components: prompter, JSON reporter, error presenter, and exit codes
│  │  ├─ prompter_test.dart  # tests interactive prompts, --yes mode, and non-TTY detection
│  │  ├─ json_reporter_test.dart  # tests that json_reporter produces stable --json output
│  │  ├─ error_presenter_test.dart  # tests turning a KilnException into a message with remediation advice
│  │  └─ exit_codes_test.dart  # tests that the fixed exit codes used by CI do not change
│  ├─ fixtures/  # small per-scenario projects used as input for the command tests
│  │  ├─ fresh_app/  # a project from create with no extra extensions, the starting point for the scenario
│  │  ├─ app_with_dio/  # a project with the dio extension installed along with its lockfile
│  │  ├─ app_with_edited_files/  # a project with render files the user has already edited, for hash and remove tests
│  │  ├─ app_with_flavors/  # a project with several AppFlavors, for testing per-flavor configuration
│  │  └─ app_without_lock/  # a project without kiln.lock.yaml, for testing project detection and doctor
│  └─ goldens/  # reference command output that must stay the same
│     ├─ add_dry_run.txt  # pins the add --dry-run text output: the file and patch plan
│     ├─ add_dry_run.json  # pins the add --dry-run JSON output read by CI
│     ├─ doctor_report.txt  # pins the doctor text report along with remediation advice
│     ├─ list.json  # pins the list --json output: installed and available extensions
│     └─ info_dio.txt  # pins the info text output for the dio extension
├─ analysis_options.yaml  # lint and static analysis rules for the kiln_cli package
├─ CHANGELOG.md  # change notes for each kiln_cli release
├─ pubspec.yaml  # kiln_cli package metadata and dependencies
└─ README.md  # introduction, installation, and CLI usage examples
```

### Command list

| Command | Purpose | Key flags |
| --- | --- | --- |
| `create` | create a project from `app_basic`, choose the state management | `--state`, `--org`, `--platforms`, `--with` |
| `add` | install extensions transactionally | `--dry-run`, `--yes`, `--no-verify`, `--from` |
| `remove` | uninstall an extension, only deleting files that have not been edited | `--dry-run`, `--force` |
| `upgrade` | bump the extension version then run migrations | `--dry-run`, `--all` |
| `rollback` | reverse the last operation from the journal | `--list` |
| `list` | installed or available extensions | `--installed`, `--available`, `--json` |
| `info` | provides, requires, platforms, and changelog of one extension | `--json` |
| `graph` | requires and capability graph | `--format text` or `mermaid` |
| `doctor` | check project health | `--fix`, `--json` |
| `config` | configure the registry, mirror, and offline mode | `--global` |
| `cache` | view or clear the registry cache | `clean` |
| `store` | search and view extensions in the registry | `search`, `info` |
| `completion` | shell autocomplete script | `bash`, `zsh`, `fish` |
| `ext` | extension author tools: `new`, `validate`, `test`, `pack`, `publish` | `--update-goldens`, `--tier` |
| `version` | CLI and `kiln_core` versions | none |

### What doctor checks

- Rendered file hashes in the lockfile are compared against the actual state,
  so files edited by the user are caught.
- Native patches that are missing or duplicated (permission, entitlement,
  intent-filter).
- `extensions.g.dart` that is out of sync with the lockfile.
- Manual steps that have not been completed, for example
  `flutterfire configure` for Firebase.
- Extensions that do not support the project's platforms, for example
  `biometric` on the web.
- Dart, Flutter, and `kiln_core` versions against each extension's
  `compatibility` range.
- Extensions that have a new version or migrations that have not been run.
- Leftover journal entries from an operation that stopped midway.
