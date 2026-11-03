## kiln_core

`kiln_core` is the only package that application code and every extension are
allowed to know about. It carries the contracts, error models, module runtime,
session state, and privacy utilities, with no dependency on any Flutter plugin.

```text
packages/kiln_core/
├─ lib/                                           # package source code, exported through the kiln_core.dart barrel
│  ├─ kiln_core.dart                              # barrel that exports the package's entire public API
│  └─ src/                                        # internal package implementation, not imported directly
│     ├─ contracts/                               # contracts that extensions implement
│     │  ├─ account_management.dart               # optional PasswordRecovery, EmailVerification, and ProfileUpdate contracts alongside AuthRepository
│     │  ├─ analytics.dart                        # Analytics contract for recording application usage events
│     │  ├─ app_flavor.dart                       # AppFlavor: a marker for the build environment currently running
│     │  ├─ auth.dart                             # AuthRepository contract for signing users in and out
│     │  ├─ connectivity.dart                     # NetworkMonitor contract for observing network connection status
│     │  ├─ crash_reporter.dart                   # CrashReporter contract for reporting crashes and errors
│     │  ├─ deep_links.dart                       # DeepLinks contract for receiving links that open the app
│     │  ├─ env.dart                              # Env contract for reading environment configuration
│     │  ├─ file_storage.dart                     # FileStorage contract: upload, download, url, and delete files in a bucket
│     │  ├─ http_client.dart                      # HttpClient contract for sending HTTP requests
│     │  ├─ local_db.dart                         # LocalDatabase contract for local data on the device
│     │  ├─ logger.dart                           # AppLogger contract for recording application logs
│     │  ├─ media_picker.dart                     # MediaPicker contract for picking images or media from the device
│     │  ├─ notifications.dart                    # Notifications contract for showing and managing notifications
│     │  ├─ permissions.dart                      # Permissions contract: check status, request permission, and open settings
│     │  ├─ remote_database.dart                  # RemoteDatabase contract: document CRUD, RemoteQuery, and watch
│     │  ├─ secure_storage.dart                   # SecureStorage contract for storing sensitive data
│     │  ├─ social_auth.dart                      # SocialAuth contract for signing in with social provider accounts
│     │  └─ storage.dart                          # Storage contract for key-value storage
│     ├─ errors/                                  # uniform error model and Result-typed operation outcomes
│     │  ├─ failure.dart                          # Failure class, the uniform error model for all contracts
│     │  ├─ failure_codes.dart                    # FailureCode class: stable codes, e.g. network.timeout and auth.invalid_credentials
│     │  └─ result.dart                           # Result<T> type holding either Ok or Err(Failure)
│     ├─ runtime/                                 # module runtime: Registry, init order, Lifecycle, bootstrap, and Slots
│     │  ├─ registry.dart                         # Registry contract for registering and resolving services
│     │  ├─ get_it_registry.dart                  # get_it-based Registry implementation
│     │  ├─ kiln_module.dart                      # KilnModule contract: a unit that registers services with the Registry on init
│     │  ├─ module_graph.dart                     # computes init order from requires and detects cycles
│     │  ├─ lifecycle.dart                        # Lifecycle contract: onReady, onPause, onResume, and dispose
│     │  ├─ bootstrap.dart                        # KilnBootstrap.run: async init with timeout and an error handler
│     │  └─ slot.dart                             # OrderedSlot<T> for http.interceptors and router.routes
│     ├─ session/                                 # login session state: session model, controller, and token provider
│     │  ├─ session.dart                          # AuthSession model with userId and expiresAt
│     │  ├─ session_controller.dart               # SessionController: unknown, authenticated, and unauthenticated status, plus a stream
│     │  └─ token_provider.dart                   # TokenProvider contract for fetching and refreshing tokens
│     ├─ privacy/                                 # user consent and personal data masking
│     │  ├─ consent.dart                          # ConsentController for analytics and crash report consent
│     │  └─ pii_redactor.dart                     # PiiRedactor masks personal data for the logger, analytics, and crash reports
│     └─ util/                                    # a fakeable Clock, a Debouncer, and a Disposable
│        ├─ clock.dart                            # Clock: a time source that can be faked in tests
│        ├─ debouncer.dart                        # Debouncer that postpones an action until calls stop
│        └─ disposable.dart                       # Disposable contract for releasing resources
├─ test/                                          # kiln_core unit tests: contracts, errors, runtime, sessions, and privacy
│  ├─ auth_test.dart                              # tests the AuthRepository contract and the Failure on wrong credentials
│  ├─ failure_test.dart                           # tests Failure construction and value comparison
│  ├─ http_client_test.dart                       # tests the HttpClient contract and network errors as Failures
│  ├─ registry_test.dart                          # tests registering and resolving services through the Registry
│  ├─ runtime_contracts_test.dart                 # tests the runtime contracts: Registry and KilnModule working together
│  ├─ result_test.dart                            # tests Result<T> as Ok or Err(Failure)
│  ├─ failure_codes_test.dart                     # verifies that FailureCode values are stable and unique
│  ├─ module_graph_test.dart                      # tests init order from requires and cycle detection
│  ├─ slot_test.dart                              # verifies that OrderedSlot<T> preserves item order
│  ├─ lifecycle_test.dart                         # verifies that Lifecycle calls onReady, onPause, onResume, and dispose
│  ├─ bootstrap_test.dart                         # tests KilnBootstrap.run: async init, timeout, and error handler
│  ├─ session_controller_test.dart                # tests SessionController status transitions and its stream
│  ├─ consent_test.dart                           # tests the ConsentController consent status for analytics and crash reports
│  ├─ pii_redactor_test.dart                      # verifies that PiiRedactor masks personal data
│  ├─ clock_test.dart                             # verifies that Clock can be faked to control time
│  └─ debouncer_test.dart                         # verifies that Debouncer only runs the last action
├─ example/                                       # an example program that uses kiln_core
│  └─ main.dart                                   # a minimal example using Registry, KilnModule, and KilnBootstrap
├─ analysis_options.yaml                          # lint and analyzer rules for this package
├─ CHANGELOG.md                                   # package change history per version
├─ pubspec.yaml                                   # package metadata and dependencies, without Flutter plugins
└─ README.md                                      # package introduction and how to use its contracts
```

