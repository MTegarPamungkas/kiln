## kiln_store, kiln_testing, kiln_lints

Three packages that close the trust and quality gaps: store downloads
extensions with verification, testing proves that every contract
implementation can stand in for another, and lints keep the app depending on
the contracts.

### kiln_store

```text
packages/kiln_store/                          # package for downloading, verifying, and publishing extensions
├─ lib/                                       # public code and implementation of the kiln_store package
│  ├─ kiln_store.dart                         # exports the kiln_store public API
│  └─ src/                                    # internal implementation of the registry client, verification, and publishing
│     ├─ registry_client.dart                 # fetches the registry index.json from the Git repository
│     ├─ registry_index.dart                  # registry index model along with the list of versions for each extension
│     ├─ registry_config.dart                 # typed configuration: URL, mirror, and ref (branch or tag)
│     ├─ version_resolver.dart                # picks the extension version that matches the project's kiln_core
│     ├─ search_index.dart                    # local extension search from the cache
│     ├─ checksum_verifier.dart               # verifies the archive sha256 before installing
│     ├─ trust_policy.dart                    # assigns the official, verified, and community levels, plus confirmation before hooks run
│     ├─ archive_packer.dart                  # creates a .tgz archive from an extension folder
│     ├─ archive_unpacker.dart                # extracts archives and rejects path traversal (zip-slip)
│     ├─ publisher.dart                       # validates an extension then publishes it to the registry
│     ├─ local_cache.dart                     # stores the index and downloaded archives on local disk
│     └─ offline_mode.dart                    # uses the local cache when the network is unavailable
├─ test/                                      # kiln_store package unit tests
│  ├─ registry_client_test.dart               # tests fetching index.json from the primary URL and the mirror
│  ├─ registry_index_test.dart                # tests parsing the registry index and the extension version lists
│  ├─ version_resolver_test.dart              # tests selecting a version compatible with the project's kiln_core
│  ├─ search_index_test.dart                  # tests local extension search from the cache
│  ├─ checksum_verifier_test.dart             # verifies that archives with a mismatched sha256 are rejected
│  ├─ trust_policy_test.dart                  # tests trust levels and confirmation before hooks run
│  ├─ archive_packer_test.dart                # tests creating a .tgz archive containing all extension files
│  ├─ archive_unpacker_test.dart              # verifies that archives with path traversal (zip-slip) are rejected
│  ├─ publisher_test.dart                     # verifies that an extension is validated before it is published
│  ├─ local_cache_test.dart                   # tests storing and reading the index and archives from the cache
│  ├─ offline_mode_test.dart                  # verifies that offline mode only uses the local cache
│  └─ fixtures/registry/                      # contains a sample index.json, a valid archive, and a malicious archive with path traversal
├─ analysis_options.yaml                      # analyzer and lint rules for the kiln_store package
├─ CHANGELOG.md                               # kiln_store change history per release
├─ pubspec.yaml                               # kiln_store package metadata and dependencies
└─ README.md                                  # usage guide and architecture for kiln_store
```

### kiln_testing

Used as a `dev_dependency` in generated applications and in every extension.
The `contracts/` suites run against every implementation: Appwrite, Firebase,
Supabase, and `rest_auth` must all pass the same `auth_repository_contract`,
and that is the proof that the backend can be swapped.

```text
packages/kiln_testing/                            # package of fakes, contract suites, and test harnesses
├─ lib/                                           # public code and implementation of the kiln_testing package
│  ├─ kiln_testing.dart                           # exports the fakes, contract suites, and harnesses
│  └─ src/                                        # internal implementation of fakes, contracts, and harnesses
│     ├─ fakes/                                   # fakes and in-memory implementations for the kiln_core contracts
│     │  ├─ fake_http_client.dart                 # simulates HttpClient with programmable responses and records requests
│     │  ├─ in_memory_storage.dart                # simulates a key-value Storage kept in memory
│     │  ├─ in_memory_secure_storage.dart         # simulates SecureStorage in memory without a real keychain
│     │  ├─ fake_auth_repository.dart             # simulates AuthRepository: login, logout, and sessions without a backend
│     │  ├─ fake_account_management.dart          # simulates AccountManagement: password reset, email verification, and profile updates
│     │  ├─ fake_social_auth.dart                 # simulates SocialAuth with configurable social login results
│     │  ├─ fake_connectivity.dart                # simulates NetworkMonitor with a changeable online or offline status
│     │  ├─ fake_permissions.dart                 # simulates Permissions with configurable permission statuses
│     │  ├─ fake_notifications.dart               # simulates Notifications and records the notifications shown
│     │  ├─ fake_deep_links.dart                  # simulates DeepLinks with incoming links triggered from the test
│     │  ├─ fake_media_picker.dart                # simulates MediaPicker with media selection results set by the test
│     │  ├─ fake_local_database.dart              # simulates a LocalDatabase that keeps data in memory
│     │  ├─ fake_remote_database.dart             # simulates RemoteDatabase in memory without a network
│     │  ├─ fake_file_storage.dart                # simulates FileStorage with file contents kept in memory
│     │  ├─ fake_analytics.dart                   # simulates Analytics and records the events sent
│     │  ├─ fake_crash_reporter.dart              # simulates CrashReporter and records the errors reported
│     │  ├─ fake_env.dart                         # simulates Env with configuration values supplied from the test
│     │  ├─ fake_clock.dart                       # simulates Clock with time advanced manually
│     │  └─ recording_logger.dart                 # an AppLogger that keeps log entries so tests can inspect them
│     ├─ contracts/                               # test suites that run against EVERY contract implementation
│     │  ├─ http_client_contract.dart             # checks HttpClient: methods, headers, body, and error mapping to Failure
│     │  ├─ storage_contract.dart                 # checks Storage: store, read, delete, and missing keys
│     │  ├─ secure_storage_contract.dart          # checks SecureStorage: values stored, read back, and deleted
│     │  ├─ auth_repository_contract.dart         # checks AuthRepository: login, logout, sessions, and the Failure on wrong credentials
│     │  ├─ account_management_contract.dart      # checks AccountManagement: password reset, email verification, and profile updates
│     │  ├─ social_auth_contract.dart             # checks SocialAuth: social login succeeding, being cancelled, and failing
│     │  ├─ local_database_contract.dart          # checks LocalDatabase: writing, reading, updating, and deleting data
│     │  ├─ remote_database_contract.dart         # checks RemoteDatabase: write, read, update, delete, and network errors
│     │  ├─ file_storage_contract.dart            # checks FileStorage: uploading, downloading, and deleting files
│     │  ├─ connectivity_contract.dart            # checks NetworkMonitor: connection status and its changes through a stream
│     │  ├─ permissions_contract.dart             # checks Permissions: permission status and the result of permission requests
│     │  ├─ notifications_contract.dart           # checks Notifications: permission, receipt, and notification handling
│     │  ├─ deep_links_contract.dart              # checks DeepLinks: the initial link and links that arrive while the app is running
│     │  ├─ media_picker_contract.dart            # checks MediaPicker: the selected media and cancellation by the user
│     │  ├─ analytics_contract.dart               # checks Analytics: event and user property submission
│     │  ├─ crash_reporter_contract.dart          # checks CrashReporter: error reporting and extra context
│     │  └─ logger_contract.dart                  # checks AppLogger: log levels and messages reaching the sink
│     └─ harness/                                 # test support tools: Registry, widgets, matchers, async, and goldens
│        ├─ test_registry.dart                    # builds a ready-to-use Registry filled with fakes for tests
│        ├─ pump_app.dart                         # renders widgets in tests with a fake Registry and the app wrappers
│        ├─ matchers.dart                         # isFailure, isOk, and hasCode matchers for Result and Failure
│        ├─ async_helpers.dart                    # pumpUntil and expectEmitsInOrder for waiting on conditions and stream order
│        └─ golden_helpers.dart                   # compares widget rendering against golden files
├─ test/                                          # kiln_testing package unit tests
│  └─ fakes_satisfy_contracts_test.dart           # verifies that every fake passes its own contract suite
├─ analysis_options.yaml                          # analyzer and lint rules for the kiln_testing package
├─ CHANGELOG.md                                   # kiln_testing change history per release
├─ pubspec.yaml                                   # kiln_testing package metadata and dependencies
└─ README.md                                      # guide to using the fakes, contract suites, and harnesses
```

### kiln_lints

```text
packages/kiln_lints/                      # optional lint plugin (Phase 6) that keeps the app using the contracts
├─ lib/                                   # public code and implementation of the kiln_lints package
│  ├─ kiln_lints.dart                     # custom_lint plugin entry point that registers all the rules
│  └─ src/rules/                          # one file per lint rule
│     ├─ no_cross_extension_import.dart   # forbids an extension from importing another extension
│     ├─ prefer_contract_over_impl.dart   # warns about app code that uses an implementation such as DioClient instead of the contract
│     ├─ no_plugin_in_features.dart       # forbids the features/ folder from importing plugins directly
│     ├─ no_edit_generated_files.dart     # warns when extensions.g.dart is edited by hand
│     └─ require_failure_handling.dart    # warns about a Result used without handling the Failure
├─ test/                                  # kiln_lints package unit tests
│  └─ rules_test.dart                     # tests each lint rule against violating and compliant code
├─ example/                               # a small example project that deliberately triggers each lint rule
├─ analysis_options.yaml                  # analyzer and lint rules for the kiln_lints package
├─ CHANGELOG.md                           # kiln_lints change history per release
├─ pubspec.yaml                           # kiln_lints package metadata and dependencies
└─ README.md                              # guide to installing the plugin and the list of lint rules
```

