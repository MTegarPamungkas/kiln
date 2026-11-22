# Changelog

## 0.1.0

- Initial release.
- `FirstRunWipe` removes only keys that match the configured storage prefix and
  uses the registered platform options; unrelated Keychain entries survive.
  The module declares its optional `storage` dependency for the wipe marker.
