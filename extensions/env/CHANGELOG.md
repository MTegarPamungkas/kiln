# Changelog

## 0.3.0

- Add `gate_env.dart` so typed reads (`envUri`, `envDuration`, `envBool`,
  `envEnum`), `validateEnv`, and `describeEnv` are one-call `Result` verbs.
- `api_base_url` no longer defaults to a placeholder; it is now genuinely
  required and the validator reports it when unset.
- `enable_debug_tools` now defaults to `false` instead of `true`.
- `BuildEnv.values` no longer includes keys whose value is empty.
- Rewrite failure messages in English.

## 0.2.0

- Removed `EnvDebugPage`. Applications read `Env` and render their own debug view.

## 0.1.1

- Add `EnvSupport` and `EnvValidator.check` so missing required keys are
  reported as `notConfigured` instead of failing bootstrap.

## 0.1.0

- Initial build-time environment, schema, validator, typed readers, summary,
  example files, and debug page.
