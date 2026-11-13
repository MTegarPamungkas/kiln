# Changelog

## 0.1.1

- Endpoints render without HTML escaping, so URLs keep their `://` and `/`.
- `remote_config` is no longer exclusive in the config category; it can be
  installed alongside build-time `env`.
- The client uses an initializing formal for its gateway to keep generated apps
  analyzer-clean.

## 0.1.0

- Initial release.
