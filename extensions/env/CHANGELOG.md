# Changelog

## 0.2.0

- Removed `EnvDebugPage`. Applications read `Env` and render their own debug view.

## 0.1.1

- Add `EnvSupport` and `EnvValidator.check` so missing required keys are
  reported as `notConfigured` instead of failing bootstrap.

## 0.1.0

- Initial build-time environment, schema, validator, typed readers, summary,
  example files, and debug page.
