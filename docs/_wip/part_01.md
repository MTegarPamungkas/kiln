## Root monorepo

The root holds everything that is not package code: CI, documentation, YAML
schemas, project templates, examples, the extension registry, and release
scripts. The contents of `extensions/` and `packages/` are described in the
following sections.

```text
kiln/
├─ .github/                                  # GitHub configuration: CI workflows, issue and PR templates, code owners
│  ├─ ISSUE_TEMPLATE/                        # issue forms contributors can choose on GitHub
│  │  ├─ bug_report.yml                      # form for reporting a bug in Kiln
│  │  ├─ extension_request.yml               # form for proposing an extension for the Kiln catalog
│  │  └─ config.yml                          # configures the issue form choices and contact links
│  ├─ workflows/                             # GitHub Actions workflows for CI, releases, and scheduled checks
│  │  ├─ ci.yaml                             # main CI pipeline: analyze and test on every push and PR
│  │  ├─ extensions.yaml                     # matrix CI that only tests the extensions that changed
│  │  ├─ bundles_check.yaml                  # fails the build when bundles have not been regenerated
│  │  ├─ smoke.yaml                          # nightly: create, add all extensions, then build apk and ios
│  │  ├─ drift.yaml                          # nightly: checks the latest versions of third-party packages used by extensions
│  │  ├─ docs.yaml                           # builds the documentation from the docs/ folder
│  │  └─ release.yaml                        # publish to pub.dev and update the registry
│  ├─ CODEOWNERS                             # list of code owners automatically asked to review PRs
│  ├─ dependabot.yml                         # schedule for automatic dependency updates by Dependabot
│  └─ PULL_REQUEST_TEMPLATE.md               # description and checklist template for every PR
├─ .vscode/                                  # shared VS Code settings for repo contributors
│  ├─ settings.json                          # attaches schemas/ to extension.yaml, kiln.yaml, and kiln.lock.yaml
│  └─ extensions.json                        # recommended Dart and YAML extensions
├─ docs/                                     # documentation for Kiln users and contributors
│  ├─ architecture.md                        # overview of the Kiln architecture and how the packages relate
│  ├─ extension-manifest.md                  # complete specification of the extension.yaml manifest fields
│  ├─ roadmap.md                             # plan for Kiln's development phases
│  ├─ folder-structure.md                    # blueprint of the Kiln folder structure (this document)
│  ├─ getting-started.md                     # guide to installing Kiln and creating your first app
│  ├─ concepts/                              # explanations of Kiln's core concepts
│  │  ├─ contracts-and-capabilities.md       # contracts in kiln_core and the capabilities extensions provide
│  │  ├─ slots.md                            # slots as the connection points between extensions
│  │  ├─ lockfile-and-ownership.md           # contents of kiln.lock.yaml and file ownership by extensions
│  │  ├─ transactions-and-rollback.md        # installation transactions and how to reverse them through the journal
│  │  ├─ native-patches.md                   # native platform file patches by extensions
│  │  ├─ compatibility.md                    # compatibility rules for Kiln, extension, and package versions
│  │  └─ security-model.md                   # security model: hooks, trust tiers, and checksums
│  ├─ cli/                                   # documentation for the kiln CLI commands
│  │  └─ reference.md                        # reference for kiln commands, flags, and usage examples
│  ├─ extensions/                            # extension documentation: catalog, how to write, test, and publish
│  │  ├─ catalog.md                          # generated from all extension.yaml files, do not edit
│  │  ├─ writing-an-extension.md             # guide to writing an extension from manifest to brick
│  │  ├─ testing-extensions.md               # how to test an extension: manifest, render, analyze, and golden
│  │  ├─ trust-tiers.md                      # extension trust levels and what they mean for users
│  │  └─ publishing.md                       # steps for publishing an extension to the registry
│  ├─ guides/                                # step-by-step guides for common scenarios
│  │  ├─ swap-backend.md                     # swapping the backend without changing application code
│  │  ├─ migrate-bloc-to-riverpod.md         # migrating state management from bloc to riverpod
│  │  ├─ add-offline-support.md              # adding offline support to an app
│  │  └─ setup-flavors-and-env.md            # setting up flavors and per-environment env files
│  └─ adr/                                   # architecture decision records
│     ├─ 0001-never-edit-user-code.md        # decision: Kiln never edits code owned by the user
│     ├─ 0002-capabilities-not-ids.md        # decision: extensions depend on capabilities, not on extension ids
│     ├─ 0003-hooks-and-trust.md             # decision: hooks run with confirmation based on trust tier
│     ├─ 0004-transactions-and-journal.md    # decision: changes are applied through transactions with a journal
│     └─ 0005-checksums-and-registry.md      # decision: archive checksums and the registry as the extension source
├─ schemas/                                  # JSON Schemas for validating and autocompleting YAML in the IDE
│  ├─ extension.schema.json                  # validates the extension.yaml manifest
│  ├─ kiln.schema.json                       # validates the kiln.yaml project configuration
│  ├─ kiln-lock.schema.json                  # validates the kiln.lock.yaml lockfile
│  ├─ migration.schema.json                  # validates migration files in extensions/<id>/migrations
│  └─ registry-index.schema.json             # validates registry/index.json
├─ bricks/                                   # Mason templates for application projects and extensions
│  ├─ app_basic/                             # basic application project brick used by kiln create
│  │  ├─ brick.yaml                          # app_basic brick metadata and project prompt variables
│  │  ├─ hooks/                              # Mason hooks that run before and after generation
│  │  │  ├─ pubspec.yaml                     # dependencies for running the hooks
│  │  │  ├─ pre_gen.dart                     # validates the app name, org, and destination folder collisions
│  │  │  └─ post_gen.dart                    # runs flutter create, adds kiln_core, pub get, format, and git init
│  │  └─ __brick__/                          # template contents rendered into the user's project
│  │     ├─ README.md                        # instructions for running and developing the generated project
│  │     ├─ kiln.yaml                        # Kiln project configuration read by the CLI
│  │     ├─ analysis_options.yaml            # Dart analyzer rules for the generated project
│  │     ├─ .gitignore                       # ignores .kiln/backups, .kiln/journal, .kiln/logs, and env/*.json except *.example.json
│  │     ├─ lib/                             # application source code
│  │     │  ├─ main.dart                     # application entry point: runs KilnBootstrap then KilnApp
│  │     │  ├─ app/                          # root widget and application shell
│  │     │  │  ├─ app.dart                   # KilnApp, the root widget that installs RegistryScope
│  │     │  │  ├─ registry_scope.dart        # RegistryScope: provides the Registry to the widget tree
│  │     │  │  ├─ app_shell.dart             # builds MaterialApp (theme, locale, router from the Registry when present), applies the app.wrappers slot
│  │     │  │  ├─ error_screen.dart          # screen shown when bootstrap fails
│  │     │  │  ├─ app_wrappers.dart          # built-in app.wrappers slot, type AppWrapper = Widget Function(BuildContext, Widget)
│  │     │  │  └─ app_route.dart             # neutral AppRoute (path, name, builder) for the router.routes slot, without importing go_router
│  │     │  └─ core/                         # core application components: l10n, theme, and error handling
│  │     │     ├─ l10n/                      # built-in app localization and the l10n extension connection point
│  │     │     │  ├─ app_localizations_config.dart  # typed configuration: AppLocalizationsConfig, the l10n extension connection point
│  │     │     │  └─ app_strings.dart        # built-in app UI text when there is no AppLocalizationsConfig in the Registry
│  │     │     ├─ theme/                     # built-in app theme and the theme extension connection point
│  │     │     │  ├─ app_theme_config.dart   # typed configuration: AppThemeConfig, the theme extension connection point
│  │     │     │  └─ app_theme.dart          # built-in app theme when there is no AppThemeConfig in the Registry
│  │     │     └─ error/                     # global error handling and user-facing error messages
│  │     │        ├─ global_error_handler.dart  # forwards Flutter and platform errors to the Logger, then to the CrashReporter when installed
│  │     │        └─ failure_presenter.dart  # turns a Failure into a user-friendly message, using l10n FailureMessages text when installed
│  │     └─ test/                            # tests that run in the generated app
│  │        └─ app/                          # tests for the application shell in lib/app
│  │           └─ app_smoke_test.dart        # verifies that KilnApp can render without errors
│  └─ extension_template/                    # empty extension skeleton, used by kiln ext new
│     ├─ brick.yaml                          # brick variables: id, name, category, provides, requires, with_hooks, with_native_patch
│     └─ __brick__/                          # template contents rendered into the extension folder
│        └─ {{id.snakeCase()}}/              # rendered extension folder, named from the id in snake_case
│           ├─ extension.yaml                # manifest: filled in from the id, name, category, provides, and requires variables
│           ├─ README.md                     # short description of the extension: what it does, how to install it, and its options
│           ├─ CHANGELOG.md                  # change history per extension version
│           ├─ docs/                         # additional extension documentation
│           │  └─ {{id.paramCase()}}.md      # extension topic documentation, file name from the id in paramCase
│           ├─ test/                         # extension-level tests, run in the kiln repo rather than in the user's app
│           │  ├─ manifest_test.dart         # verifies that extension.yaml is valid against extension.schema.json
│           │  ├─ render_test.dart           # verifies that rendering the brick to a temp folder matches the golden
│           │  └─ analyze_test.dart          # verifies that the rendered result passes dart analyze without warnings
│           └─ brick/                        # the extension's Mason brick, rendered into the user's project via kiln add
│              ├─ brick.yaml                 # extension brick metadata and its prompt variables
│              ├─ hooks/                     # Mason hooks, created when with_hooks is set
│              │  ├─ pubspec.yaml            # dependencies for running the hooks
│              │  ├─ pre_gen.dart            # validates input before the brick is rendered
│              │  └─ post_gen.dart           # runs follow-up steps after the brick is rendered
│              └─ __brick__/                 # brick contents rendered into the user's project
│                 ├─ lib/extensions/{{id.snakeCase()}}/  # extension code that goes into the user project's lib/
│                 │  ├─ {{id.snakeCase()}}.dart          # static facade with a short API for application code to use
│                 │  ├─ {{id.snakeCase()}}_module.dart   # registers the extension's services with the Registry
│                 │  ├─ {{id.snakeCase()}}_config.dart   # typed configuration: values filled in from prompts
│                 │  └─ {{id.snakeCase()}}_failure_mapper.dart  # turns third-party package errors into Failures
│                 └─ test/extensions/{{id.snakeCase()}}/  # extension tests that go into the user project's test/
│                    ├─ {{id.snakeCase()}}_module_test.dart          # verifies that the module registers its services with the Registry
│                    └─ {{id.snakeCase()}}_failure_mapper_test.dart  # verifies that third-party errors map to the right Failure
├─ extensions/                               # 29 extension folders, described in the Extension section
├─ examples/                                 # example generated projects as a reference for using Kiln
│  ├─ minimal/                               # the result of kiln create without extensions
│  │  ├─ kiln.yaml                           # project configuration without extensions
│  │  ├─ kiln.lock.yaml                      # lockfile with no extensions installed
│  │  ├─ pubspec.yaml                        # minimal project dependencies without extension packages
│  │  ├─ lib/                                # generated minimal application code
│  │  └─ test/                               # built-in tests for the minimal application
│  ├─ full_stack/                            # installs bloc, dio, http_retry, rest_auth, secure_storage, go_router, theme, l10n, env, logger
│  │  ├─ kiln.yaml                           # project configuration with all extensions installed
│  │  ├─ kiln.lock.yaml                      # lockfile recording the version and files owned by each extension
│  │  ├─ pubspec.yaml                        # project dependencies, including the package from each extension
│  │  ├─ lib/                                # application code along with extension code in lib/extensions
│  │  └─ test/                               # application tests along with extension tests in test/extensions
│  ├─ backend_swap/                          # proves the backend can be swapped without changing app code
│  │  ├─ README.md                           # explains the backend swap scenario and how to compare the two variants
│  │  ├─ with_appwrite/                      # project variant with an Appwrite backend
│  │  └─ with_supabase/                      # project variant with a Supabase backend; only kiln.yaml and lib/extensions differ
│  └─ custom_extension/                      # the result of kiln ext new: a complete example community extension
├─ registry/                                 # extension index and version metadata, generated by tool/build_registry.dart
│  ├─ index.json                             # list of extensions: id, latest version, and tier
│  ├─ README.md                              # explains the registry format and how to use it
│  └─ extensions/                            # release metadata, one folder per extension
│     ├─ dio/                                # release metadata for the dio extension, one json per version
│     │  ├─ 1.0.0.json                       # 1.0.0 release metadata: archive url, sha256, requires, compatibility
│     │  └─ 1.1.0.json                       # 1.1.0 release metadata with the same fields
│     └─ <id>/                               # one folder per extension, containing one json per version
├─ tool/                                     # Dart scripts for bundling, registry, checks, and releases
│  ├─ bundle.dart                            # bundles all bricks with mason bundle, with a --check flag for CI
│  ├─ smoke_test.dart                        # tests the create flow and adding all extensions through to a build
│  ├─ build_registry.dart                    # generates registry/index.json and the version json for each extension
│  ├─ check_drift.dart                       # compares extension constraints with the latest versions on pub.dev
│  ├─ lint_extensions.dart                   # runs kiln ext validate on all extensions
│  ├─ gen_catalog_docs.dart                  # writes docs/extensions/catalog.md from all extension.yaml files
│  └─ release.dart                           # bumps the version, writes the changelog, and creates the tag
├─ packages/                                 # 6 Dart packages, described per package below
│  ├─ kiln_cli/                              # the kiln CLI: create, add, upgrade, rollback, and doctor commands
│  ├─ kiln_core/                             # contracts, error models, module runtime, session state, and privacy utilities
│  ├─ kiln_extension_sdk/                    # the kiln add engine: read manifests, compute plans, render bricks, apply transactions
│  ├─ kiln_store/                            # registry client: fetch the index, pick a version, verify checksums, trust policy
│  ├─ kiln_testing/                          # fakes per contract, contract suites, and test harnesses
│  └─ kiln_lints/                            # custom_lint rules for Kiln projects, optional (Phase 6)
├─ CONTRIBUTING.md                           # contribution guide: repo setup, code style, and the PR flow
├─ SECURITY.md                               # security policy and how to report vulnerabilities
├─ CODE_OF_CONDUCT.md                        # code of conduct for the contributor community
├─ LICENSE                                   # the Kiln project license text
├─ .gitignore                                # ignores build artifacts and local files in the repo
├─ analysis_options.yaml                     # shared Dart analyzer rules for the entire monorepo
├─ pubspec.yaml                              # dependencies for the tool/ scripts and monorepo dev tooling
├─ pubspec.lock                              # pins the dependency versions of the monorepo root
└─ README.md                                 # introduction to the Kiln project and links to the documentation
```

