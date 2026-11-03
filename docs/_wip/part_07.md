### supabase

```text
extensions/supabase/
├─ extension.yaml  # manifest: provides: auth, social_auth, remote_database, file_storage · category: auth · exclusive · prompts: url, anon_key (secret), schema · android: url_schemes
├─ README.md  # extension introduction, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # extension documentation for app developers
│  ├─ supabase-setup.md  # steps to set up a Supabase project and fill in the url and anon key
│  ├─ row-level-security.md  # example policies for tables used by RemoteDatabase
│  └─ email-confirmation-and-redirects.md  # callback through the DeepLinks contract when deep_link is installed
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason template that renders extension code into the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and template variables
   └─ __brick__/  # template contents rendered into the user app project
      ├─ lib/extensions/supabase/  # supabase extension source code in the generated app
      │  ├─ supabase_module.dart  # registers auth, social_auth, remote_database, and file_storage in the Registry
      │  ├─ supabase_auth_repository.dart  # AuthRepository implementation through Supabase Auth
      │  ├─ supabase_client.dart  # creates the Supabase client from the url and anon key
      │  ├─ supabase_gateway.dart  # wraps supabase_flutter so it can be faked in tests
      │  ├─ supabase_failure_mapper.dart  # turns Supabase errors into a Failure
      │  ├─ supabase_config.dart  # typed configuration: url, anon key, schema, PKCE flow
      │  ├─ supabase_account_management.dart  # AccountManagement implementation: password reset, email verification, profile update
      │  ├─ supabase_token_provider.dart  # provides a TokenProvider from the session access token
      │  ├─ supabase_session_bridge.dart  # forwards onAuthStateChange to SessionController
      │  ├─ supabase_link_handler.dart  # receives the email confirmation callback through DeepLinks (readOrNull)
      │  ├─ postgrest_gateway.dart  # wraps PostgREST so it can be faked: interface and SdkPostgrestGateway
      │  ├─ supabase_remote_database.dart  # RemoteDatabase implementation: document CRUD and queries through PostgREST
      │  ├─ supabase_query_mapper.dart  # converts RemoteQuery into PostgREST filters
      │  ├─ supabase_realtime_gateway.dart  # wraps the Supabase realtime channel for watch() so it can be faked
      │  ├─ supabase_storage_gateway.dart  # wraps Supabase Storage so it can be faked: interface and SdkSupabaseStorageGateway
      │  └─ supabase_file_storage.dart  # FileStorage implementation with signed URLs through Supabase Storage
      └─ test/extensions/supabase/  # supabase extension code tests in the generated app
         ├─ supabase_auth_test.dart  # verifies the Supabase AuthRepository flow with a faked gateway
         ├─ supabase_failure_mapper_test.dart  # verifies that Supabase errors map to a Failure with the right FailureCode
         ├─ supabase_module_test.dart  # verifies that the module registers every contract in the Registry
         ├─ supabase_config_test.dart  # verifies the default configuration values for url, anon key, schema, and PKCE
         ├─ supabase_account_management_test.dart  # verifies password reset, email verification, and profile update
         ├─ supabase_token_provider_test.dart  # verifies that the token is taken from the active session access token
         ├─ supabase_session_bridge_test.dart  # verifies that auth state changes are forwarded to SessionController
         ├─ supabase_link_handler_test.dart  # verifies receipt of the email confirmation callback through DeepLinks
         ├─ supabase_remote_database_test.dart  # verifies RemoteDatabase document CRUD against a fake PostgrestGateway
         ├─ supabase_query_mapper_test.dart  # verifies that RemoteQuery is translated into the correct PostgREST filters
         ├─ supabase_file_storage_test.dart  # verifies upload, download, delete, and signed URL on FileStorage
         └─ supabase_contract_test.dart  # runs the auth, social_auth, remote_database, and file_storage contract suites from kiln_testing
```

### rest_auth

```text
extensions/rest_auth/
├─ extension.yaml  # manifest: provides: auth · requires: http_client, secure_storage · category: auth · exclusive · prompts: base_url, path login, register, refresh, logout, me
├─ README.md  # extension introduction, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # extension documentation for app developers
│  ├─ rest-auth.md  # guide to installing rest_auth and filling in base_url and the endpoint paths
│  ├─ server-contract.md  # JSON shapes of the login, register, refresh, logout, and me requests and responses
│  └─ token-refresh.md  # the single-flight refresh flow and when a session counts as ended
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason template that renders extension code into the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and template variables
   └─ __brick__/  # template contents rendered into the user app project
      ├─ lib/extensions/rest_auth/  # rest_auth extension source code in the generated app
      │  ├─ rest_auth_module.dart  # registers RestAuth as AuthRepository in the Registry
      │  ├─ rest_auth.dart  # AuthRepository implementation (the RestAuth class) through HttpClient and REST endpoints
      │  ├─ rest_auth_config.dart  # typed configuration: base_url and the login, register, refresh, logout, and me paths
      │  ├─ rest_auth_failure_mapper.dart  # turns HTTP statuses and server error bodies into a Failure
      │  ├─ rest_token_store.dart  # stores the access and refresh tokens through SecureStorage
      │  ├─ token_refresher.dart  # performs a single-flight refresh, parallel requests wait for one result
      │  ├─ jwt_expiry.dart  # reads the JWT exp without verification to refresh before expiry
      │  ├─ auth_response_parser.dart  # parses auth responses: camelCase or snake_case, varying token shapes
      │  ├─ auth_middleware.dart  # adds the Bearer header, contributes: http.interceptors (priority 10)
      │  ├─ unauthorized_handler.dart  # handles 401: refresh, retry once, signOut on failure
      │  ├─ rest_account_management.dart  # AccountManagement implementation: password reset and email verification through optional endpoints
      │  └─ rest_session_bridge.dart  # fills SessionController and TokenProvider from the RestAuth session
      └─ test/extensions/rest_auth/  # rest_auth extension code tests in the generated app
         ├─ rest_auth_test.dart  # verifies RestAuth as AuthRepository against a fake HttpClient
         ├─ rest_auth_module_test.dart  # verifies that the module registers AuthRepository in the Registry
         ├─ rest_auth_failure_mapper_test.dart  # verifies the mapping of HTTP statuses and error bodies to a Failure
         ├─ rest_token_store_test.dart  # verifies storing, reading, and deleting tokens in SecureStorage
         ├─ token_refresher_test.dart  # verifies that parallel requests share a single refresh
         ├─ jwt_expiry_test.dart  # verifies JWT exp parsing and the refresh cutoff before expiry
         ├─ auth_response_parser_test.dart  # verifies parsing of camelCase, snake_case, and varying token shapes
         ├─ auth_middleware_test.dart  # verifies that the Bearer header is added to requests
         ├─ unauthorized_handler_test.dart  # verifies that 401 triggers a refresh, one retry, and signOut on failure
         ├─ rest_account_management_test.dart  # verifies password reset and email verification through optional endpoints
         ├─ rest_session_bridge_test.dart  # verifies that SessionController and TokenProvider are filled from the session
         └─ rest_auth_contract_test.dart  # runs the auth_repository_contract suite from kiln_testing against this implementation
```

### social_login

```text
extensions/social_login/
├─ extension.yaml  # manifest: requires: social_auth · category: social · prompts: google_server_client_id, google_ios_client_id, apple_service_id · ios: apple_sign_in
├─ README.md  # extension introduction, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # extension documentation for app developers
│  ├─ social-login.md  # guide to installing social_login and filling in the Google and Apple client ids
│  ├─ google-setup.md  # sets up the Android, iOS, and server Google client ids plus SHA-1
│  └─ apple-setup.md  # sets up the capability, service id, and Apple on Android or the web
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason template that renders extension code into the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and template variables
   └─ __brick__/  # template contents rendered into the user app project
      ├─ lib/extensions/social_login/  # social_login extension source code in the generated app
      │  ├─ social_login_module.dart  # registers SocialLogin in the Registry
      │  ├─ social_login.dart  # SocialLogin implementation for signing in with Google and Apple
      │  ├─ social_credentials.dart  # fetches credentials from the Google and Apple SDKs through gateways
      │  ├─ social_login_failure_mapper.dart  # turns Google and Apple SDK errors into a Failure
      │  ├─ social_login_config.dart  # typed configuration: client ids and the enabled providers
      │  ├─ nonce_generator.dart  # creates a secure random nonce and its SHA-256 hash for Apple
      │  ├─ social_availability.dart  # determines which social providers are available on the running platform
      │  ├─ google_credential_gateway.dart  # wraps google_sign_in so it can be faked: interface and SdkGoogleCredentialGateway
      │  ├─ apple_credential_gateway.dart  # wraps sign_in_with_apple so it can be faked: interface and SdkAppleCredentialGateway
      │  ├─ social_sign_out_listener.dart  # signs out of the Google session when AuthRepository.signOut is called
      │  └─ widgets/  # ready-made widgets for social sign-in
      │     ├─ social_login_buttons.dart  # Google and Apple buttons following brand guidelines and availability
      │     └─ social_login_panel.dart  # ready-made panel with a loading state and Failure messages
      └─ test/extensions/social_login/  # social_login extension code tests in the generated app
         ├─ social_login_test.dart  # verifies the SocialLogin flow for Google and Apple with faked gateways
         ├─ social_login_failure_mapper_test.dart  # verifies the mapping of Google and Apple SDK errors to a Failure
         ├─ social_login_module_test.dart  # verifies that the module registers SocialLogin in the Registry
         ├─ social_login_config_test.dart  # verifies the client id configuration values and the enabled providers
         ├─ nonce_generator_test.dart  # verifies nonce randomness and the correctness of the SHA-256 hash
         ├─ social_availability_test.dart  # verifies the providers available per platform
         ├─ social_sign_out_listener_test.dart  # verifies that AuthRepository signOut triggers signing out of Google
         ├─ social_login_buttons_test.dart  # verifies that the buttons render according to provider availability
         ├─ social_login_panel_test.dart  # verifies the loading state and Failure messages on the panel
         └─ social_auth_contract_test.dart  # runs the social_auth contract suite from kiln_testing against this implementation
```

### biometric

```text
extensions/biometric/
├─ extension.yaml  # manifest: provides: biometric · category: security · android: USE_BIOMETRIC, FlutterFragmentActivity · ios: NSFaceIDUsageDescription · platforms: android, ios, macos (not web)
├─ README.md  # extension introduction, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # extension documentation for app developers
│  ├─ biometric.md  # guide to installing the biometric extension and using the Biometric facade
│  ├─ app-lock.md  # how the app lock works after the app goes to the background
│  └─ platform-requirements.md  # platform requirements: AppCompat theme on Android 8 and below, and the web limits
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason template that renders extension code into the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and template variables
   └─ __brick__/  # template contents rendered into the user app project
      ├─ lib/extensions/biometric/  # biometric extension source code in the generated app
      │  ├─ biometric.dart  # Biometric facade: canAuthenticate, availableBiometrics, and authenticate
      │  ├─ biometric_module.dart  # registers the Biometric facade in the Registry
      │  ├─ biometric_config.dart  # typed configuration: default reason, grace period, biometricOnly
      │  ├─ biometric_failure_mapper.dart  # turns plugin errors into a Failure: a table of codes to FailureCode with their messages
      │  ├─ biometric_gateway.dart  # wraps LocalAuthentication so it can be faked: interface and SdkBiometricGateway
      │  ├─ biometric_availability.dart  # reports availability status: available, notEnrolled, noHardware, unsupportedPlatform
      │  ├─ biometric_gate.dart  # guards actions through guard(action): authenticate first, grace period via Clock
      │  ├─ app_lock.dart  # locks when onPause exceeds the limit, unlocks through biometrics
      │  ├─ app_lock_scope.dart  # screen cover widget while locked, contributes: app.wrappers
      │  └─ biometric_protected_storage.dart  # SecureStorage implementation that requires authentication before read (readOrNull)
      └─ test/extensions/biometric/  # biometric extension code tests in the generated app
         ├─ biometric_test.dart  # verifies the Biometric facade: canAuthenticate, availableBiometrics, and authenticate
         ├─ biometric_module_test.dart  # verifies that the module registers Biometric in the Registry
         ├─ biometric_config_test.dart  # verifies the default reason, grace period, and biometricOnly values
         ├─ biometric_failure_mapper_test.dart  # verifies the mapping of plugin error codes to FailureCode and their messages
         ├─ biometric_availability_test.dart  # verifies determination of the available, notEnrolled, noHardware, unsupportedPlatform statuses
         ├─ biometric_gate_test.dart  # verifies the guard: authenticate first and grace period using a fake Clock
         ├─ app_lock_test.dart  # verifies that the lock activates after onPause exceeds the limit
         ├─ app_lock_scope_test.dart  # verifies that the screen is covered while locked and opens after authentication
         └─ biometric_protected_storage_test.dart  # verifies that read requires authentication first
```

