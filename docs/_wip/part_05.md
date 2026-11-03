## Extensions: state and networking

These five extensions form the foundation of an application: one state
management adapter (exclusive) and an HTTP stack assembled from `dio`,
`http_retry`, and `http_cache` through the `http.interceptors` slot.

### bloc

```text
extensions/bloc/                            # state management extension based on Bloc and Cubit
├─ extension.yaml                           # manifest: category: state · exclusive · provides: state_bloc (riverpod is rejected by the exclusive rule)
├─ README.md                                # short guide to installing and using the bloc extension
├─ CHANGELOG.md                             # changelog of the bloc extension per version
├─ docs/                                    # documentation on using the bloc extension
│  ├─ state-with-bloc.md                    # guide to managing app state with Cubit and Bloc
│  └─ bloc-to-riverpod.md                   # guide to migrating state from bloc to riverpod
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata and its list of variables
   └─ __brick__/                            # template contents copied into the generated app
      ├─ lib/                               # Dart code copied into the app lib/
      │  ├─ bootstrap.dart                  # sets up the Registry and AppBlocObserver before runApp
      │  ├─ app/                            # app-level composition for global state
      │  │  └─ bloc_providers.dart          # MultiBlocProvider for global blocs
      │  ├─ core/bloc/                      # Bloc and Cubit foundation shared by every feature
      │  │  ├─ app_bloc_observer.dart       # logs transitions and errors to the Logger with PII redacted
      │  │  ├─ base_cubit.dart              # safeEmit (checks isClosed), runGuarded becomes a Failure
      │  │  ├─ async_state.dart             # sealed: initial, loading, data, failure
      │  │  ├─ async_cubit.dart             # load, refresh, retry
      │  │  ├─ bloc_transformers.dart       # debounce, throttle, droppable, restartable
      │  │  └─ session_cubit.dart           # wraps SessionController from kiln_core
      │  └─ features/                       # sample feature that uses Bloc state
      │     └─ counter/                     # counter feature as an example of Cubit usage
      │        ├─ counter_cubit.dart        # Cubit that holds the counter value and changes it
      │        └─ counter_page.dart         # counter page that reads CounterCubit through BlocBuilder
      └─ test/                              # tests also generated into the user app
         ├─ bootstrap_test.dart             # verifies that bootstrap installs the Bloc observer and sets up the Registry
         ├─ counter_cubit_test.dart         # verifies that CounterCubit changes state in response to actions
         ├─ counter_page_test.dart          # verifies that CounterPage shows the counter value and reacts to the buttons
         └─ core/bloc/                      # tests for the Bloc foundation in core/bloc
            ├─ app_bloc_observer_test.dart  # verifies that the observer records transitions and errors with PII redacted
            ├─ base_cubit_test.dart         # verifies that safeEmit does not emit when isClosed and runGuarded becomes a Failure
            ├─ async_state_test.dart        # verifies the sealed AsyncState variants: initial, loading, data, failure
            ├─ async_cubit_test.dart        # verifies that load, refresh, and retry produce the correct state sequence
            ├─ bloc_transformers_test.dart  # verifies the behavior of the debounce, throttle, droppable, and restartable transformers
            └─ session_cubit_test.dart      # verifies that SessionCubit forwards the status of SessionController
```

### riverpod

```text
extensions/riverpod/                        # state management extension based on Riverpod
├─ extension.yaml                           # manifest: category: state · exclusive · provides: state_riverpod (bloc is rejected by the exclusive rule)
├─ README.md                                # short guide to installing and using the riverpod extension
├─ CHANGELOG.md                             # changelog of the riverpod extension per version
├─ docs/                                    # documentation on using the riverpod extension
│  ├─ state-with-riverpod.md                # guide to managing app state with providers and Notifier
│  └─ riverpod-to-bloc.md                   # guide to migrating state from riverpod to bloc
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata and its list of variables
   └─ __brick__/                            # template contents copied into the generated app
      ├─ lib/                               # Dart code copied into the app lib/
      │  ├─ bootstrap.dart                  # sets up the Registry and ProviderScope before runApp
      │  ├─ app/                            # app-level composition for global state
      │  │  └─ provider_root.dart           # ProviderScope with a Registry override
      │  ├─ core/riverpod/                  # Riverpod foundation shared by every feature
      │  │  ├─ kiln_providers.dart          # registryProvider and kilnProvider<T>() for every contract
      │  │  ├─ app_provider_observer.dart   # logs provider errors with PII redacted
      │  │  ├─ async_value_x.dart           # AsyncValue extension: guard becomes a Failure and concise when mapping
      │  │  ├─ provider_overrides.dart      # ready-made overrides for tests
      │  │  └─ session_notifier.dart        # wraps SessionController from kiln_core
      │  └─ features/                       # sample feature that uses Riverpod state
      │     └─ counter/                     # counter feature as an example of provider usage
      │        ├─ counter_page.dart         # counter page that reads state from the provider
      │        └─ counter_provider.dart     # provider that holds the counter value and changes it
      └─ test/                              # tests also generated into the user app
         ├─ bootstrap_test.dart             # verifies that bootstrap sets up the ProviderScope with the Registry
         ├─ counter_page_test.dart          # verifies that CounterPage shows the counter value and reacts to the buttons
         ├─ counter_provider_test.dart      # verifies that the counter provider changes state in response to actions
         └─ core/riverpod/                  # tests for the Riverpod foundation in core/riverpod
            ├─ kiln_providers_test.dart     # verifies that registryProvider and kilnProvider<T>() take contracts from the Registry
            ├─ app_provider_observer_test.dart  # verifies that the observer records provider errors with PII redacted
            ├─ async_value_x_test.dart      # verifies that guard turns exceptions into a Failure and when maps state
            ├─ provider_overrides_test.dart  # verifies that test overrides replace contracts with fakes
            └─ session_notifier_test.dart   # verifies that SessionNotifier forwards the status of SessionController
```

### dio

```text
extensions/dio/                             # HTTP client extension based on dio that opens the interceptor slot
├─ extension.yaml                           # manifest: provides: http_client, http_pipeline · opens slot: http.interceptors · android: INTERNET · macos: network.client
├─ README.md                                # short guide to installing and using the dio extension
├─ CHANGELOG.md                             # changelog of the dio extension per version
├─ docs/                                    # documentation on using the dio extension
│  ├─ http-client.md                        # guide to making requests and handling errors through HttpClient
│  └─ interceptors.md                       # how other extensions attach to the http.interceptors slot
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata and variables such as base_url and connect_timeout
   ├─ hooks/                                # Mason hooks that run during generation
   │  ├─ pubspec.yaml                       # dependencies required by the hook scripts
   │  └─ pre_gen.dart                       # validates base_url and connect_timeout before rendering
   └─ __brick__/                            # template contents copied into the generated app
      ├─ lib/extensions/dio/                # dio extension code in the generated app
      │  ├─ http.dart                       # static Http facade: get, post, put, patch, delete
      │  ├─ dio_module.dart                 # registers HttpClient and HttpPipeline in the Registry
      │  ├─ dio_client.dart                 # HttpClient contract implementation on top of Dio with HttpPipeline
      │  ├─ dio_config.dart                 # typed configuration: base_url, timeout, default headers
      │  ├─ dio_failure_mapper.dart         # turns DioException errors into a Failure (timeout, offline, 401, 5xx)
      │  ├─ cancellation.dart               # cancels the request when the widget is disposed
      │  ├─ multipart_helper.dart           # uploads multipart files with progress reporting
      │  ├─ download_helper.dart            # downloads files with progress reporting
      │  ├─ dio_test_adapter.dart           # fake HTTP adapter so tests do not touch the network
      │  └─ interceptors/                   # built-in interceptors and the slot entry point
      │     ├─ interceptor_slot.dart        # entry point for contributes from other extensions
      │     ├─ request_id_interceptor.dart  # adds the X-Request-Id header for log correlation
      │     └─ user_agent_interceptor.dart  # adds a User-Agent header with the app version and platform
      └─ test/extensions/dio/               # tests also generated for the dio extension
         ├─ dio_client_test.dart            # verifies that DioClient sends requests and returns a Result
         ├─ dio_module_test.dart            # verifies that the module registers HttpClient and HttpPipeline in the Registry
         ├─ dio_failure_mapper_test.dart    # verifies that DioException is mapped to a Failure (timeout, offline, 401, 5xx)
         ├─ cancellation_test.dart          # verifies that the request is cancelled when the widget is disposed
         ├─ multipart_helper_test.dart      # verifies that multipart upload sends files and reports progress
         ├─ download_helper_test.dart       # verifies that downloads write files and report progress
         ├─ interceptor_slot_test.dart      # verifies that slot contributions are installed in priority order
         ├─ request_id_interceptor_test.dart  # verifies that every request carries the X-Request-Id header
         ├─ user_agent_interceptor_test.dart  # verifies that the User-Agent header contains the app version and platform
         └─ http_client_contract_test.dart  # runs the HttpClient contract suite from kiln_testing against this implementation
```

### http_retry

```text
extensions/http_retry/                      # automatic retry extension for HTTP requests that fail temporarily
├─ extension.yaml                           # manifest: requires: http_client, http_pipeline · contributes: http.interceptors, priority 20 (attached to HttpPipeline)
├─ README.md                                # short guide to installing and using the http_retry extension
├─ CHANGELOG.md                             # changelog of the http_retry extension per version
├─ docs/                                    # documentation on using the http_retry extension
│  └─ retry-policy.md                       # guide to configuring the retry policy, backoff, and budget
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata and its list of variables
   └─ __brick__/                            # template contents copied into the generated app
      ├─ lib/extensions/http_retry/         # http_retry extension code in the generated app
      │  ├─ http_retry_module.dart          # registers RetryMiddleware in the Registry and the HttpPipeline
      │  ├─ retry_middleware.dart           # HttpMiddleware that repeats failed requests according to the policy
      │  ├─ retry_policy.dart               # decides which failures are worth retrying and how many times
      │  ├─ retry_settings.dart             # typed settings: attempt count, initial delay, and backoff ceiling
      │  ├─ backoff.dart                    # computes exponential delay with jitter
      │  ├─ retry_budget.dart               # caps total retries per time window, preventing retry storms
      │  ├─ retry_after_parser.dart         # parses the Retry-After header (seconds or an HTTP date)
      │  ├─ idempotency.dart                # retries only idempotent methods or those with an Idempotency-Key
      │  └─ retry_events.dart               # fires callbacks and logs on every retry attempt
      └─ test/extensions/http_retry/        # tests also generated for the http_retry extension
         ├─ http_retry_test.dart            # verifies that temporary failures are retried according to the policy
         ├─ backoff_test.dart               # verifies that the delay grows exponentially and jitter stays within bounds
         ├─ retry_budget_test.dart          # verifies that retries stop when the time-window budget is exhausted
         ├─ retry_after_parser_test.dart    # verifies that Retry-After is parsed correctly both as seconds and as an HTTP date
         └─ idempotency_test.dart           # verifies that only idempotent methods or those with an Idempotency-Key are retried
```

### http_cache

```text
extensions/http_cache/                      # HTTP response cache extension with optional storage
├─ extension.yaml                           # manifest: requires: http_client, http_pipeline · optional storage (when: [storage]) · contributes: http.interceptors, priority 30
├─ README.md                                # short guide to installing and using the http_cache extension
├─ CHANGELOG.md                             # changelog of the http_cache extension per version
├─ docs/                                    # documentation on using the http_cache extension
│  └─ caching-strategies.md                 # guide to choosing a cache strategy and invalidation
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/                                   # Mason brick rendered into the user app
   ├─ brick.yaml                            # Mason brick metadata and its list of variables
   └─ __brick__/                            # template contents copied into the generated app
      ├─ lib/extensions/http_cache/         # http_cache extension code in the generated app
      │  ├─ http_cache_module.dart          # registers HttpCache in the Registry and the interceptor in the HttpPipeline
      │  ├─ cache_policy.dart               # decides which responses may be stored and for how long
      │  ├─ cache_settings.dart             # typed settings: cache strategy, TTL, and maximum size
      │  ├─ memory_http_cache.dart          # HttpCache implementation in process memory
      │  ├─ cache_store.dart                # cache entry store interface used by the HttpCache implementations
      │  ├─ storage_http_cache.dart         # persistent HttpCache through the Storage contract
      │  ├─ cache_interceptor.dart          # cache HttpMiddleware attached to the http.interceptors slot
      │  ├─ cache_key.dart                  # builds the cache key from the URL, query, and Vary header
      │  ├─ cache_control_parser.dart       # parses Cache-Control: max-age, no-store, no-cache, stale-while-revalidate
      │  ├─ etag_validator.dart             # revalidates the ETag through If-None-Match and 304 responses
      │  ├─ stale_while_revalidate.dart     # serves the stale entry then refreshes it in the background
      │  └─ cache_invalidation.dart         # drops entries by prefix or tag after a mutation request
      └─ test/extensions/http_cache/        # tests also generated for the http_cache extension
         ├─ http_cache_test.dart            # verifies that responses are served from the cache according to the policy
         ├─ cache_key_test.dart             # verifies that the cache key contains the URL, query, and Vary header
         ├─ cache_control_parser_test.dart  # verifies that Cache-Control directives are parsed correctly
         ├─ etag_validator_test.dart        # verifies that the ETag triggers If-None-Match and a 304 response uses the cache
         ├─ stale_while_revalidate_test.dart  # verifies that the stale entry is served then refreshed in the background
         ├─ cache_invalidation_test.dart    # verifies that a mutation request drops entries by prefix or tag
         └─ storage_http_cache_test.dart    # verifies that the persistent cache stores and reads entries through Storage
```

