## kiln_extension_sdk

The SDK is the engine behind `kiln add`: it reads manifests, computes plans,
renders bricks, then applies the changes in a transaction that can be reversed.
The `installer/` section is the largest, and its three subfolders
(`transaction/`, `ownership/`, `verification/`) are what keep `add` and `remove`
safe.

```text
packages/kiln_extension_sdk/
├─ lib/                                                     # SDK source code: manifest, resolver, renderer, installer, migrator
│  ├─ kiln_extension_sdk.dart                               # barrel that exports the SDK's public API
│  ├─ testing.dart                                          # ExtensionTestHarness for extension authors' own tests
│  └─ src/                                                  # internal SDK implementation, used through the barrel
│     ├─ kiln_exception.dart                                # KilnException, the exception for failures in the SDK process
│     ├─ manifest/                                          # extension.yaml models and validation
│     │  ├─ extension_manifest.dart                         # ExtensionManifest model parsed from extension.yaml
│     │  ├─ platform_setup.dart                             # model for the platform block in the manifest covering Android, iOS, macOS, and web patches
│     │  ├─ slot.dart                                       # model for a slot that an extension opens in the manifest
│     │  ├─ manifest_validator.dart                         # validates id, semver, requires cycles, and platform fields
│     │  ├─ prompt_spec.dart                                # url, int, enum, and secret prompt types along with their validation
│     │  ├─ compatibility.dart                              # checks the version ranges of kiln_core, Dart, Flutter, and platforms
│     │  └─ contribution.dart                               # contributes model for slots, with an optional when condition holding capabilities
│     ├─ resolver/                                          # computes installation plans, conflicts, and upgrades
│     │  ├─ extension_resolver.dart                         # resolves requires and provides into a list of installed extensions
│     │  ├─ resolution_plan.dart                            # model for the resolution plan that the installer applies
│     │  ├─ capability_index.dart                           # capability index: which extension provides what
│     │  ├─ conflict_report.dart                            # builds actionable extension conflict messages
│     │  ├─ dependency_graph.dart                           # requires graph for the kiln graph and kiln remove commands
│     │  └─ upgrade_planner.dart                            # plans an extension upgrade from the installed version to a target version
│     ├─ renderer/                                          # renders Mason bricks into files in the user's project
│     │  ├─ brick_renderer.dart                             # renders a Mason brick into the user's project with template variables
│     │  ├─ template_vars.dart                              # turns prompt answers and kiln.yaml into Mason variables
│     │  ├─ collision_policy.dart                           # decides skip, overwrite, or ask; detects edited files through hashes
│     │  └─ hook_policy.dart                                # allows hooks only when the brick is trusted
│     ├─ installer/                                         # applies extensions to a project: transactions, ownership, native patches, verification
│     │  ├─ extension_installer.dart                        # orchestrates adding and removing extensions inside a transaction
│     │  ├─ extensions_codegen.dart                         # writes extensions.g.dart in the user's project so it stays in sync with the lockfile
│     │  ├─ lockfile.dart                                   # reads and writes kiln.lock.yaml containing the installed extensions
│     │  ├─ pubspec_reader.dart                             # reads dependencies and versions from the user's pubspec.yaml
│     │  ├─ pubspec_writer.dart                             # adds and removes dependencies in pubspec.yaml through yaml_edit
│     │  ├─ transaction/                                    # transactions that can be reversed: journal, snapshot, and rollback
│     │  │  ├─ transaction.dart                             # runs installation steps and records them in the journal
│     │  │  ├─ journal.dart                                 # records the steps that have run as material for rollback
│     │  │  ├─ snapshot.dart                                # backs up files to .kiln/backups before they are changed
│     │  │  └─ rollback.dart                                # restores the project to its initial state from the journal and snapshots
│     │  ├─ ownership/                                      # tracks the owners of rendered files and patches
│     │  │  ├─ file_ownership.dart                          # records the hash of every rendered file
│     │  │  └─ patch_journal.dart                           # records the owner of each patch with a reference count
│     │  ├─ native/                                         # patches native Android, iOS, macOS, and web files in the user's project
│     │  │  ├─ native_setup.dart                            # applies all native patches according to the platform block in the manifest
│     │  │  ├─ patch.dart                                   # Patch interface with describe, apply, and revert
│     │  │  ├─ android_gradle.dart                          # edits the Android build.gradle in the user's project for the build settings an extension needs
│     │  │  ├─ android_project.dart                         # edits AndroidManifest.xml in the user's project: permissions such as INTERNET and app links
│     │  │  ├─ ios_app_delegate.dart                        # edits the iOS AppDelegate in the user's project for native code an extension needs
│     │  │  ├─ ios_entitlements.dart                        # edits the iOS entitlements file in the user's project, e.g. associated domains
│     │  │  ├─ ios_plist.dart                               # adds iOS Info.plist keys in the user's project, e.g. permission reason strings
│     │  │  ├─ ios_podfile.dart                             # adds PERMISSION_* flags to the iOS Podfile for permission_handler
│     │  │  ├─ macos_entitlements.dart                      # edits macOS entitlements in the user's project, e.g. network.client and device.camera
│     │  │  └─ web_index_html.dart                          # edits web/index.html in the user's project for tags an extension needs
│     │  └─ verification/                                   # checks on the apply result and dry run reports
│     │     ├─ verifier.dart                                # runs pub get and dart analyze after apply
│     │     └─ dry_run_reporter.dart                        # reports the diff that would happen without writing files
│     └─ migrator/                                          # extension migration between versions
│        ├─ migration.dart                                  # Migration model: the steps that change an extension between versions
│        ├─ migration_actions.dart                          # migration actions: rename_file, delete_file, replace_dependency, update_config, message
│        ├─ migration_loader.dart                           # reads migrations from extensions/<id>/migrations
│        └─ migration_runner.dart                           # runs migrations in order when upgrading an extension
├─ test/                                                    # SDK unit tests along with test data in fixtures
│  ├─ android_deep_links_test.dart                          # tests the AndroidManifest.xml patch for app links and deep links
│  ├─ android_gradle_test.dart                              # tests the Android build.gradle patch
│  ├─ brick_renderer_test.dart                              # tests rendering a brick into a project folder with template variables
│  ├─ installer_test.dart                                   # tests the add and remove flows of ExtensionInstaller on an example project
│  ├─ ios_entitlements_test.dart                            # tests adding and removing iOS entitlements keys
│  ├─ manifest_test.dart                                    # tests parsing extension.yaml into an ExtensionManifest
│  ├─ resolver_test.dart                                    # tests resolution of requires, provides, and exclusive by ExtensionResolver
│  ├─ transaction_test.dart                                 # verifies that Transaction runs the steps and records the journal
│  ├─ rollback_test.dart                                    # verifies that rollback restores the project after a step fails
│  ├─ snapshot_test.dart                                    # tests backing up files to .kiln/backups and restoring them
│  ├─ file_ownership_test.dart                              # tests recording the hashes of rendered files
│  ├─ patch_journal_test.dart                               # tests the reference count of a patch owned by several extensions
│  ├─ pubspec_writer_test.dart                              # tests adding and removing dependencies through yaml_edit
│  ├─ ios_podfile_test.dart                                 # tests adding PERMISSION_* flags to the iOS Podfile
│  ├─ macos_entitlements_test.dart                          # tests the macOS entitlements patch
│  ├─ web_index_html_test.dart                              # tests the web/index.html patch
│  ├─ manifest_validator_test.dart                          # tests validation of id, semver, requires cycles, and platform fields
│  ├─ prompt_spec_test.dart                                 # tests the url, int, enum, and secret prompt types along with their validation
│  ├─ compatibility_test.dart                               # tests the version range checks for kiln_core, Dart, Flutter, and platforms
│  ├─ contribution_test.dart                                # tests contributes to slots with a when condition holding capabilities
│  ├─ capability_index_test.dart                            # tests the capability index: which extension provides what
│  ├─ conflict_report_test.dart                             # tests the actionable conflict messages
│  ├─ dependency_graph_test.dart                            # tests the requires graph for kiln graph and kiln remove
│  ├─ upgrade_planner_test.dart                             # tests the extension upgrade plan between versions
│  ├─ collision_policy_test.dart                            # tests the skip, overwrite, and ask decisions on file collisions
│  ├─ hook_policy_test.dart                                 # verifies that hooks only run on trusted bricks
│  ├─ template_vars_test.dart                               # tests building Mason variables from prompts and kiln.yaml
│  ├─ verifier_test.dart                                    # tests verification with pub get and dart analyze after apply
│  ├─ dry_run_reporter_test.dart                            # tests the dry run diff report without writing files
│  ├─ migration_runner_test.dart                            # tests sequential migration execution by MigrationRunner
│  ├─ migration_actions_test.dart                           # tests the rename_file, delete_file, replace_dependency, and update_config migration actions
│  └─ fixtures/                                             # test data: manifests, example projects, and small bricks
│     ├─ manifests/                                         # sample extension.yaml files for the manifest and validator tests
│     │  ├─ valid/                                          # extension.yaml files that must pass validation
│     │  └─ invalid/                                        # invalid extension.yaml files that the validator must reject
│     ├─ projects/                                          # sample Flutter projects as installation targets
│     │  ├─ fresh_app/                                      # a fresh app with no extensions, for the first add scenario
│     │  ├─ app_with_dio/                                   # an app with dio installed, for scenarios with an extension that depends on http_pipeline
│     │  ├─ app_with_edited_files/                          # an app with rendered files edited by the user, for the file collision scenario
│     │  └─ app_with_two_owners/                            # an app with a patch owned by two extensions, for the reference count scenario
│     └─ bricks/                                            # small Mason bricks for the renderer tests
│        ├─ tiny_brick/                                     # a minimal brick for the basic render scenario
│        └─ brick_with_hooks/                               # a brick with hooks, for the hook_policy and trusted brick scenarios
├─ tool/                                                    # SDK package development scripts
│  └─ generate_schemas.dart                                 # generates JSON Schemas from the manifest models
├─ analysis_options.yaml                                    # lint and analyzer rules for this package
├─ CHANGELOG.md                                             # package change history per version
├─ pubspec.yaml                                             # SDK package metadata and dependencies
└─ README.md                                                # SDK introduction and how to build extensions
```

