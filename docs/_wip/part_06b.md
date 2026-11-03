## Extensions: backend and auth

Six extensions for identity and remote data. The three backends (`appwrite`,
`firebase`, `supabase`) satisfy three contracts at once: `AuthRepository`,
`RemoteDatabase`, and `FileStorage`. `rest_auth` satisfies `AuthRepository`
only, on top of `http_client`. `social_login` and `biometric` add sign-in
paths without changing the auth contract.

Backends deliberately have **no** static facade. App code reads contracts from
the Registry, and the `prefer_contract_over_impl` lint rule rejects direct
imports of backend classes.

Every backend uses the same gateway pattern, so session logic and error mapping
can be tested without a real account:

```text
kiln_core contract ←  <backend>_auth_repository / _remote_database / _file_storage
                              ↓ uses
                       <backend>_*_gateway (interface)  ←  Sdk*Gateway (plugin) | Fake (test)
```

### appwrite

```text
extensions/appwrite/
├─ extension.yaml  # manifest: provides: auth, remote_database, file_storage · category: auth · exclusive · prompts: endpoint, project_id, database_id, bucket_id
├─ README.md  # extension overview: what it does, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # documentation on setup, permissions, and Appwrite behavior differences
│  ├─ appwrite-setup.md  # create the project, platform, database, and bucket
│  ├─ collections-and-permissions.md  # document permissions and the supported RemoteQuery features
│  └─ backend-swap-notes.md  # behavior differences compared with firebase and supabase
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason brick rendered into extension code in the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and variables
   └─ __brick__/  # template files rendered into the user app folder
      ├─ lib/extensions/appwrite/  # appwrite extension source code rendered into the user app
      │  ├─ appwrite_module.dart  # registers AuthRepository, RemoteDatabase, and FileStorage in the Registry
      │  ├─ appwrite_auth.dart  # implements AuthRepository with the Appwrite Account service
      │  ├─ appwrite_account.dart  # wraps Appwrite Account service calls for use by appwrite_auth
      │  ├─ appwrite_config.dart  # typed configuration: endpoint, projectId, databaseId, bucketId
      │  ├─ appwrite_client_factory.dart  # creates the Client with setSelfSigned only in the development flavor
      │  ├─ appwrite_failure_mapper.dart  # turns Appwrite errors into a Failure (401, 404, 409, 429, network)
      │  ├─ appwrite_account_management.dart  # implements AccountManagement: password reset, email verification, profile update
      │  ├─ appwrite_session_bridge.dart  # fills SessionController and TokenProvider from kiln_core
      │  ├─ appwrite_database_gateway.dart  # wraps Appwrite Databases through SdkAppwriteDatabaseGateway so it can be faked in tests
      │  ├─ appwrite_remote_database.dart  # implements RemoteDatabase on top of the Appwrite database gateway
      │  ├─ appwrite_query_mapper.dart  # converts RemoteQuery into an Appwrite Query
      │  ├─ appwrite_realtime_gateway.dart  # wraps Realtime subscriptions for watch() so they can be faked in tests
      │  ├─ appwrite_storage_gateway.dart  # wraps Appwrite Storage through SdkAppwriteStorageGateway so it can be faked in tests
      │  └─ appwrite_file_storage.dart  # implements FileStorage: upload, download, url, delete
      └─ test/extensions/appwrite/  # appwrite extension tests rendered into the user app
         ├─ appwrite_auth_test.dart  # verifies the sign-in, sign-out, and session flow of AuthRepository with a fake Account
         ├─ appwrite_module_test.dart  # verifies that the module registers the Appwrite contracts in the Registry
         ├─ appwrite_config_test.dart  # verifies that configuration is read from endpoint, projectId, databaseId, and bucketId
         ├─ appwrite_failure_mapper_test.dart  # verifies the mapping of 401, 404, 409, 429, and network errors to a Failure
         ├─ appwrite_account_management_test.dart  # verifies password reset, email verification, and profile update, including failures
         ├─ appwrite_session_bridge_test.dart  # verifies that the Appwrite session fills SessionController and TokenProvider
         ├─ appwrite_remote_database_test.dart  # verifies RemoteDatabase operations with a fake database gateway
         ├─ appwrite_query_mapper_test.dart  # verifies that RemoteQuery is translated into the correct Appwrite Query
         ├─ appwrite_realtime_gateway_test.dart  # verifies that the Realtime subscription is closed on dispose
         ├─ appwrite_file_storage_test.dart  # verifies file upload, download, url, and delete with a fake storage gateway
         └─ appwrite_contract_test.dart  # runs the auth, remote_database, and file_storage contract suites from kiln_testing against this implementation
```

### firebase

```text
extensions/firebase/
├─ extension.yaml  # manifest: provides: auth, social_auth, remote_database, file_storage · category: auth · exclusive · manual_steps: flutterfire configure
├─ README.md  # extension overview: what it does, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # documentation on setup, emulators, and Firebase security rules
│  ├─ firebase-setup.md  # guide to creating a Firebase project and connecting it to the app
│  ├─ flutterfire-configure.md  # manual steps tracked by doctor
│  ├─ emulators.md  # the development flavor uses the Firebase Emulator Suite
│  └─ security-rules.md  # example Firestore and Storage rules that match RemoteQuery
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason brick rendered into extension code in the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and variables
   ├─ hooks/  # Mason hooks that run while the brick is generated
   │  ├─ pubspec.yaml  # package dependencies for running the hooks
   │  └─ pre_gen.dart  # checks the flutterfire CLI and firebase_options.dart, only warns
   └─ __brick__/  # template files rendered into the user app folder
      ├─ lib/extensions/firebase/  # firebase extension source code rendered into the user app
      │  ├─ firebase_module.dart  # registers AuthRepository, SocialAuth, RemoteDatabase, and FileStorage in the Registry
      │  ├─ firebase_app.dart  # initializes Firebase before other services are used
      │  ├─ firebase_auth_repository.dart  # implements AuthRepository on top of FirebaseAuth through a gateway
      │  ├─ firebase_gateway.dart  # wraps FirebaseAuth so it can be faked in tests
      │  ├─ firebase_failure_mapper.dart  # turns Firebase errors into a Failure
      │  ├─ firebase_config.dart  # typed configuration: options source, emulator host, emulator flag
      │  ├─ firebase_emulator.dart  # points auth, firestore, and storage at the emulators in the development flavor
      │  ├─ firebase_account_management.dart  # implements AccountManagement: password reset, email verification, profile update
      │  ├─ firebase_id_token_provider.dart  # implements TokenProvider from getIdToken with automatic refresh
      │  ├─ firebase_session_bridge.dart  # forwards authStateChanges to SessionController
      │  ├─ firestore_gateway.dart  # wraps Firestore through SdkFirestoreGateway so it can be faked in tests
      │  ├─ firestore_remote_database.dart  # implements RemoteDatabase on top of Firestore
      │  ├─ firestore_query_mapper.dart  # converts RemoteQuery into a Firestore query, rejecting combinations without an index
      │  ├─ firebase_storage_gateway.dart  # wraps Firebase Storage through SdkFirebaseStorageGateway so it can be faked in tests
      │  └─ firebase_file_storage.dart  # implements FileStorage with upload progress
      └─ test/extensions/firebase/  # firebase extension tests rendered into the user app
         ├─ firebase_auth_test.dart  # verifies the sign-in, sign-out, and session flow of AuthRepository with a fake FirebaseAuth
         ├─ firebase_failure_mapper_test.dart  # verifies the mapping of Firebase errors to a Failure
         ├─ firebase_module_test.dart  # verifies that the module registers the Firebase contracts in the Registry
         ├─ firebase_config_test.dart  # verifies that configuration picks the options source and the emulator flag
         ├─ firebase_emulator_test.dart  # verifies that auth, firestore, and storage point at the emulators in the development flavor
         ├─ firebase_account_management_test.dart  # verifies password reset, email verification, and profile update, including failures
         ├─ firebase_id_token_provider_test.dart  # verifies that the ID token is fetched through getIdToken and refreshed automatically
         ├─ firebase_session_bridge_test.dart  # verifies that authStateChanges updates SessionController
         ├─ firestore_remote_database_test.dart  # verifies RemoteDatabase operations with a fake Firestore gateway
         ├─ firestore_query_mapper_test.dart  # verifies that RemoteQuery becomes a Firestore query and combinations without an index are rejected
         ├─ firebase_file_storage_test.dart  # verifies FileStorage operations and upload progress with a fake storage gateway
         └─ firebase_contract_test.dart  # runs the auth, social_auth, remote_database, and file_storage contract suites from kiln_testing against this implementation
```

