# Changelog

## 0.1.2

- Test the gateway's empty-content validation (the one code path in the real
  gateway that runs without the plugin).

## 0.1.1

- Pass null instead of an empty file list; share_plus rejects an empty
  `files` list when sharing text only.

## 0.1.0

- Add `ShareService`, the share_plus gateway, runtime support reporting, and
  platform declarations.
