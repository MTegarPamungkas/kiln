# env

Typed build-time configuration from `--dart-define`.

- `BuildEnv` reads values compiled into the app, not files at runtime.
- `EnvSchema` defines the active keys, types, required flags, and secrets.
- `EnvValidator` collects every missing required key into a single
  `Failure(configuration)`.
- `EnvX` provides `uri`, `duration`, `boolValue`, and `enumValue` readers.
- `EnvDescribe` redacts secret values for logs.
- Applications can render their own debug view from `Env` and `EnvDescribe`.

The keys available today are `api_base_url`, `api_key`, `feature_flags`, and
`enable_debug_tools`. See [docs/env.md](docs/env.md) for adding keys.

## Gate

```dart
final apiKey = gate.env.read('API_KEY');  // String?
final all = gate.env.values;              // Map<String, String>
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
