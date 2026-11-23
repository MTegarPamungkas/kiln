# Changelog

## 0.1.2

- Cover the optional `storage` requirement and the `cacheTtl`/`refreshOnResume`
  settings in the manifest and render tests.

## 0.1.1

- Persist every successful fetch when the `storage` extension is installed, and
  serve a snapshot newer than `cacheTtl` when the endpoint is unreachable, so
  feature gates keep their last known values offline. The client exposes
  `lastFetchFailure` and `isUsingCachedValues`.

- A snapshot that finishes fetching after disposal is no longer activated
  on a closed client.
- Activate the snapshot fetched by the support probe without a duplicate
  bootstrap download.
- Superseded fetches cannot activate pending snapshots. Closing fences queued
  and in-flight fetches, rejects later mutations and closes the gateway once.
- Endpoints render without HTML escaping, so URLs keep their `://` and `/`.
- `remote_config` is no longer exclusive in the config category; it can be
  installed alongside build-time `env`.
- The client uses an initializing formal for its gateway to keep generated apps
  analyzer-clean.

## 0.1.0

- Initial release.
