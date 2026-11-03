# Changelog

## 0.1.4

- `kiln create` defaults to the minimal template; `--template app` restores
  the starter page.
- `kiln upgrade` keeps installed extensions resolvable while validating the
  candidate, so a failed upgrade no longer leaves other extensions unknown.
- Bundle `kiln_core` 0.1.2 and the support-aware biometric, permission,
  notifications, and l10n extensions.

## 0.1.3

- `kiln doctor` warns when an extension is disabled on some project platforms
  instead of failing the whole project.

## 0.1.2

- Beautify `kiln store search/info` with an aligned table, installed/update
  status, structured info sections, and friendlier prompt metadata.

## 0.1.1

- Add `kiln repair` to restore generated extension files, preserve ARBs unless
  `--force`, and re-sync `extensions.g.dart` in the same run.

## 0.1.0

- Commands create, add, remove, list, info, graph, doctor, rollback, config,
  cache, store, completion, upgrade, version, and ext tooling.
