# Changelog

## 0.2.0

- Removed `FlavorBanner` and the automatic `app.wrappers` contribution. Applications read `AppFlavor` and render their own flavor indicator.

## 0.1.1

- Add `FlavorsSupport` to report the registered flavor and banner state.
- A missing `AppFlavor` is reported as `notConfigured` instead of silently
  disabling the banner and release guard.

## 0.1.0

- Initial flavor values, entry points, banner wrapper, release guard, and
  launch configurations.
