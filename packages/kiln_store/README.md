# kiln_store

Registry client, archive verification, trust policy, and extension publisher for
Kiln. This package does not depend on Flutter, so it can be used by the CLI, the
registry tool, and release scripts.

## Package contents

| File | Responsibility |
| --- | --- |
| `registry_config.dart` | Base URL, mirror, ref, and normalization of local/`file:` paths |
| `registry_client.dart` | Fetches `index.json` and archives over HTTP, `file:`, or a local folder |
| `registry_index.dart` | `index.json` models (`RegistryIndex`, `RegistryExtension`, `RegistryVersion`) |
| `version_resolver.dart` | Picks the highest version compatible with `kiln_core` (and Dart) |
| `search_index.dart` | Local search by id, name, description, and category |
| `checksum_verifier.dart` | SHA-256 verification of archives before install |
| `trust_policy.dart` | Trust levels (official/verified/community) and hook confirmation |
| `archive_packer.dart` | Builds a deterministic `.tar.gz` from an extension folder |
| `archive_unpacker.dart` | Extracts archives and rejects path traversal and links |
| `publisher.dart` | Validates the manifest, then writes the archive and `index.json` |
| `local_cache.dart` | On-disk cache for the index and archives |
| `offline_mode.dart` | Uses the cache when offline or when the network fails |
| `kiln_store_exception.dart` | Errors with `code`, `message`, `suggestion`, `details` |

## Registry configuration

```dart
final config = RegistryConfig(
  url: 'https://raw.githubusercontent.com/example/registry/main',
  mirror: 'https://mirror.example.dev/kiln',
);

config.indexUri;        // .../index.json
config.mirrorIndexUri;  // .../index.json or null
config.resolve('archives/dio-0.2.0.tgz');
```

`url` and `mirror` accept HTTP(S) URLs, `file:` URIs, or filesystem paths
(including `C:\registry` on Windows). Local paths are normalized to `file:`
when a URI is needed. The `{ref}` placeholder is replaced with `ref` when the
path is resolved, so a single configuration can follow a branch or tag.

`RegistryConfig.fromMap`/`toJson` are used by the CLI configuration.

## Fetching the index and archives

```dart
final cache = LocalCache(Directory(cacheDir));
final client = RegistryClient(config: config, cache: cache);
final index = await client.fetchIndex();

final extension = index.find('dio')!;
final version = extension.findVersion('0.2.0')!;
final bytes = await client.downloadArchive(
  extension.id,
  version,
  indexUri: config.indexUri,
);
```

`fetchIndex` uses the primary registry first and the mirror as a fallback;
`useMirror: true` reverses the order. Non-200 responses, missing files, and
network failures become a `KilnStoreException` with the code
`store.fetch_failed`. `downloadArchive` always verifies the SHA-256 and writes
to the cache when one is available.

## Selecting versions and searching extensions

```dart
final selected = const VersionResolver().resolve(
  extension,
  kilnVersion: Version.parse('0.1.0'),
  installedVersion: '0.1.0',
  dartVersion: Version.parse('3.9.0'),
);

final matches = SearchIndex(index).search('http');
```

The resolver only accepts versions that satisfy the `compatibility['kiln']`
constraint (and `compatibility['dart']` when provided), skips prereleases
unless `allowPrerelease: true`, and never selects a version equal to or lower
than the installed version. A missing constraint is treated as compatible; a
malformed constraint is skipped.

## Trust policy

```dart
final decision = const TrustPolicy().evaluate(manifest, hasHooks: true);
if (!decision.allowed) { /* tolak */ }
if (decision.requiresConfirmation) { /* minta konfirmasi */ }
```

Official is always allowed. Verified and community follow `allowed` (default:
all tiers). Community asks for confirmation when `confirmCommunity` is set, and
extensions with hooks ask for confirmation when `confirmHooks` is set.

## Archives

```dart
final bytes = const ArchivePacker().pack(extensionRoot);
const ArchiveUnpacker().extract(bytes, target);

final sha256 = sha256Hex(bytes);
const ChecksumVerifier().verify(bytes, expectedSha256);
```

Packer writes POSIX relative paths, sorts entries, uses fixed timestamps and
modes, and skips `.dart_tool`, `.git`, `build`, `.kiln`, and the `.tgz` archives
it generates. Because of this, identical content produces identical bytes, which
`tool/registry.dart --check` requires.

Unpacker validates every entry before writing anything, then rejects absolute
paths, drive letters, empty segments, `..`, backslashes, symlinks, hard links,
and special files with the code `store.unsafe_archive`. Archives that are not
`.tar.gz` are rejected with `store.invalid_archive`.

## Cache and offline mode

```dart
final mode = OfflineMode(client: client, cache: cache, offline: true);
final index = await mode.index();
final bytes = await mode.archive('dio', '0.2.0');
```

Offline mode never touches the network: the index is read from the cache or a
`store.offline_missing` error is thrown, and an archive that is not cached also
throws `store.offline_missing` (after confirming the id/version exists in the
index). In online mode, a failure to fetch the index falls back to the cache
when one is available.

Cache layout:

```text
<cache>/index.json
<cache>/archives/<id>-<version>.tgz
```

## Publish

```dart
final result = await Publisher().publish(
  extensionRoot: extension,
  registryRoot: registry,
  archiveBaseUrl: Uri.parse('https://cdn.example.dev/kiln'), // optional
);
```

Publisher validates `extension.yaml` with `ManifestValidator`, rejects
duplicate versions unless `force: true`, writes
`registry/archives/<id>-<version>.tgz`, computes the SHA-256, and then updates
`registry/index.json`. Other extensions and versions are preserved; extensions
are sorted by id and versions in ascending order. `latest` is always the highest
version. Without `archiveBaseUrl`, the archive URL is stored relative as
`archives/<id>-<version>.tgz`.

## Running tests

```bash
cd packages/kiln_store
dart test
dart analyze
```

Fixtures live in `test/fixtures/registry/`: `index.json`, `valid.tgz`, and
`zip-slip.tgz` (a malicious archive for testing path traversal rejection).
