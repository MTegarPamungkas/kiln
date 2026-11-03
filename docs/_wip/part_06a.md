## Extensions: storage and data

Three local storage extensions, from the simplest (key-value) to the encrypted
one and the document-based one. They do not import each other: `http_cache`
and `rest_auth` use `Storage` and `SecureStorage` through the contracts in
`kiln_core`.

### storage

```text
extensions/storage/
├─ extension.yaml  # manifest: provides: storage · category: storage
├─ README.md  # extension overview: what it does, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # documentation on using storage and migrating keys
│  ├─ key-value-storage.md  # guide to reading and writing values through Prefs and Storage
│  └─ typed-keys-and-migration.md  # how to name keys and migrate old values
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason brick rendered into extension code in the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and variables
   └─ __brick__/  # template files rendered into the user app folder
      ├─ lib/extensions/storage/  # storage extension source code rendered into the user app
      │  ├─ prefs.dart  # static Prefs.read, write, delete facade, named Prefs so it does not clash with Storage
      │  ├─ storage_module.dart  # registers a SharedPreferences-based Storage in the Registry
      │  ├─ shared_preferences_storage.dart  # implements key-value Storage on top of shared_preferences
      │  ├─ storage_config.dart  # typed configuration: key prefix per app and flavor
      │  ├─ storage_failure_mapper.dart  # turns plugin errors and bad casts into Failure(storage)
      │  ├─ storage_gateway.dart  # wraps SharedPreferencesAsync so it can be faked in tests
      │  ├─ typed_key.dart  # defines StorageKey<T> with name, type, default, and serializer
      │  ├─ json_codec.dart  # stores objects through jsonEncode and jsonDecode
      │  ├─ namespaced_storage.dart  # wraps Storage with a prefix, used by http_cache without overwriting other keys
      │  ├─ ttl_storage.dart  # stores values with an expiry, using Clock from kiln_core
      │  └─ storage_migrator.dart  # manages key schema versions and runs migration steps at startup
      └─ test/extensions/storage/  # storage extension tests rendered into the user app
         ├─ shared_preferences_storage_test.dart  # verifies that values are stored, read, and deleted through a fake gateway
         ├─ storage_module_test.dart  # verifies that the module registers Storage in the Registry
         ├─ storage_failure_mapper_test.dart  # verifies the mapping of plugin errors and bad casts to Failure(storage)
         ├─ typed_key_test.dart  # verifies the default value and serializer on StorageKey<T>
         ├─ json_codec_test.dart  # verifies that objects are stored and read back through JSON
         ├─ namespaced_storage_test.dart  # verifies that the prefix separates keys and does not overwrite other keys
         ├─ ttl_storage_test.dart  # verifies that values expire according to the test-controlled Clock
         ├─ storage_migrator_test.dart  # verifies that migration steps run when the key schema version is older
         └─ storage_contract_test.dart  # runs the Storage contract suite from kiln_testing against this implementation
```

### secure_storage

```text
extensions/secure_storage/
├─ extension.yaml  # manifest: provides: secure_storage · ios: keychain_sharing · android: allowBackup=false
├─ README.md  # extension overview: what it does, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # documentation on secure storage and platform differences
│  ├─ secure-storage.md  # guide to storing secrets through Vault and SecureStorage
│  └─ keystore-and-keychain-notes.md  # data loss on reinstall, backups, and platform differences
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason brick rendered into extension code in the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and variables
   └─ __brick__/  # template files rendered into the user app folder
      ├─ lib/extensions/secure_storage/  # secure_storage extension source code rendered into the user app
      │  ├─ vault.dart  # static Vault.read, write, and delete facade for secret data
      │  ├─ secure_storage_module.dart  # registers SecureStorage in the Registry
      │  ├─ keystore_secure_storage.dart  # implements SecureStorage on top of Keychain and Keystore
      │  ├─ secure_storage_config.dart  # typed configuration: Android options (encrypted prefs), iOS (accessibility), web
      │  ├─ secure_storage_failure_mapper.dart  # turns plugin errors into Failure(secure_storage)
      │  ├─ secure_storage_gateway.dart  # wraps FlutterSecureStorage so it can be faked in tests
      │  ├─ secure_token_store.dart  # implements TokenProvider from kiln_core, used by rest_auth
      │  ├─ namespaced_secure_storage.dart  # prefixes keys per extension so readAll and clear never touch other owners
      │  ├─ first_run_wipe.dart  # clears Keychain leftovers from old installs on the first iOS start
      │  └─ secure_storage_health_check.dart  # runs a write-read-delete probe and reports the result to doctor and the Logger
      └─ test/extensions/secure_storage/  # secure_storage extension tests rendered into the user app
         ├─ secure_storage_test.dart  # verifies that secrets are stored, read, and deleted through a fake gateway
         ├─ secure_storage_module_test.dart  # verifies that the module registers SecureStorage in the Registry
         ├─ secure_storage_failure_mapper_test.dart  # verifies the mapping of plugin errors to Failure(secure_storage)
         ├─ secure_token_store_test.dart  # verifies that tokens are stored and read through TokenProvider
         ├─ namespaced_secure_storage_test.dart  # verifies that readAll and clear only touch keys with their own prefix
         ├─ first_run_wipe_test.dart  # verifies that old Keychain data is cleared only on the first iOS start
         ├─ secure_storage_health_check_test.dart  # verifies that the write-read-delete probe reports results to doctor and the Logger
         └─ secure_storage_contract_test.dart  # runs the SecureStorage contract suite from kiln_testing against this implementation
```

### local_db

```text
extensions/local_db/
├─ extension.yaml  # manifest: provides: local_db · category: database · exclusive
├─ README.md  # extension overview: what it does, how to install it, and usage examples
├─ CHANGELOG.md  # changelog of the extension per version
├─ docs/  # documentation on the local database, schema, and offline-first patterns
│  ├─ local-database.md  # guide to using LocalDatabase, collections, and queries
│  ├─ schema-versioning.md  # how to use document migrations
│  └─ offline-first-pattern.md  # offline-first patterns, used by guides/add-offline-support.md
├─ test/                                    # extension-level tests, run in the kiln repo and not in the user app
│  ├─ manifest_test.dart                    # verifies that extension.yaml is valid against extension.schema.json
│  ├─ render_test.dart                      # renders the brick into a temp folder, the output must match the golden
│  ├─ analyze_test.dart                     # the rendered output must pass dart analyze with no warnings
│  └─ goldens/rendered/                     # reference render output for render_test, produced by kiln ext test --update-goldens
└─ brick/  # Mason brick rendered into extension code in the user app
   ├─ brick.yaml  # Mason brick metadata: name, version, and variables
   └─ __brick__/  # template files rendered into the user app folder
      ├─ lib/extensions/local_db/  # local_db extension source code rendered into the user app
      │  ├─ local_db_module.dart  # registers LocalDatabase in the Registry
      │  ├─ sembast_local_database.dart  # implements LocalDatabase on top of Sembast
      │  ├─ local_database_opener.dart  # opens the Sembast database, picking the IO or web variant per platform
      │  ├─ local_database_opener_io.dart  # opens the file-based Sembast database on Android, iOS, and desktop
      │  ├─ local_database_opener_web.dart  # opens the IndexedDB-based Sembast database on the web
      │  ├─ local_db_config.dart  # typed configuration: database file name, schema version, path override
      │  ├─ local_db_failure_mapper.dart  # turns Sembast errors into Failure(database)
      │  ├─ collection_watcher.dart  # provides a Stream<List<LocalRecord>> updated whenever the collection changes
      │  ├─ transaction_runner.dart  # runs several operations in one atomic transaction
      │  ├─ typed_collection.dart  # builds a typed LocalCollection with fromJson and toJson
      │  ├─ query_builder.dart  # assembles where, orderBy, and limit into a LocalQuery
      │  ├─ schema_migrator.dart  # runs migration steps for the schema version when the database is opened
      │  ├─ database_encryption.dart  # provides optional encryption through a Sembast codec, with the key from SecureStorage when available
      │  ├─ backup_export.dart  # exports and imports the whole database as JSON
      │  └─ sync_queue.dart  # queues local changes to be synced to RemoteDatabase
      └─ test/extensions/local_db/  # local_db extension tests rendered into the user app
         ├─ local_database_test.dart  # verifies that LocalDatabase stores, reads, and deletes documents
         ├─ local_db_module_test.dart  # verifies that the module registers LocalDatabase in the Registry
         ├─ local_db_failure_mapper_test.dart  # verifies the mapping of Sembast errors to Failure(database)
         ├─ collection_watcher_test.dart  # verifies that the collection stream emits new data when the collection changes
         ├─ transaction_runner_test.dart  # verifies that transactions are atomic and roll back when one operation fails
         ├─ typed_collection_test.dart  # verifies fromJson and toJson conversion on a typed LocalCollection
         ├─ query_builder_test.dart  # verifies that where, orderBy, and limit become the correct LocalQuery
         ├─ schema_migrator_test.dart  # verifies that migration steps run for the schema version on open
         ├─ database_encryption_test.dart  # verifies that an encrypted database is readable only with the same key
         ├─ backup_export_test.dart  # verifies that exporting then importing JSON restores the whole database
         ├─ sync_queue_test.dart  # verifies that the queue holds local changes for syncing
         └─ local_database_contract_test.dart  # runs the LocalDatabase contract suite from kiln_testing against this implementation
```

