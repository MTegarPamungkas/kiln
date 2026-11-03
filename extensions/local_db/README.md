# local_db

Implementation of `LocalDatabase` from `kiln_core` on top of Sembast.

Features:

- key-value document collections,
- `where`, `orderBy`, `limit`, and `offset` queries,
- collection change streams,
- atomic transactions,
- typed collections with `fromJson`/`toJson`,
- JSON export/import backup,
- sync queue for RemoteDatabase,
- schema migrations,
- optional AES-GCM encryption with keys from SecureStorage.
