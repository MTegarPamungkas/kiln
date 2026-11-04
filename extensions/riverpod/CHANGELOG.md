# Changelog

## 0.3.0

- Cache `kilnProvider<T>()` by type so every call returns the same `Provider`
  instance. Riverpod identifies providers by object identity, so the previously
  fresh-per-call provider made inline `ref.watch(kilnProvider<Contract>())`
  create a separate provider node each time; watchers of the same contract now
  share one node. Covered by an identity test.

## 0.2.0

- Removed the counter demo provider and page. The extension keeps the provider scope, observer, and registry bridge.

## 0.1.2

- Add `RiverpodSupport` with app-wrapper details.
- Create the slot registry when a module is used without bootstrap, and make
  the bootstrap test independent of the starter template.

## 0.1.1

- Bootstrap test supplies a test `CoreCopy`, matching the app template now that
  the shell requires `l10n`.

## 0.1.0

- Initial Riverpod foundation, Registry providers, session notifier, and
  counter example.
