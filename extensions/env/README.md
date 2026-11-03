# env

Typed build-time configuration from `--dart-define`.

- `BuildEnv` reads values compiled into the app, not files at runtime.
- `EnvSchema` defines the active keys, types, required flags, and secrets.
- `EnvValidator` collects every missing required key into a single
  `Failure(configuration)`.
- `EnvX` provides `uri`, `duration`, `boolValue`, and `enumValue` readers.
- `EnvDescribe` redacts secret values for logs.
- `EnvDebugPage` only appears in non-production flavors.

The keys available today are `api_base_url`, `api_key`, `feature_flags`, and
`enable_debug_tools`. See [docs/env.md](docs/env.md) for adding keys.
