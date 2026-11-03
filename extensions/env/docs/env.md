# Environment

```dart
final env = registry.read<Env>();

final baseUrl = env.uri(EnvKeys.apiBaseUrl);
final debugTools = env.boolValue(EnvKeys.enableDebugTools) ?? false;
```

Values come from `--dart-define`:

```bash
flutter run --dart-define=api_base_url=https://api.kiln.dev
```

Or from a JSON file:

```bash
flutter run --dart-define-from-file=env/development.json
```

## Keys

| Key | Type | Required | Secret |
| --- | --- | --- | --- |
| `api_base_url` | URI | yes | no |
| `api_key` | string | no | yes |
| `feature_flags` | string | no | no |
| `enable_debug_tools` | bool | no | no |

Keys selected at install time go into `EnvSchema.defaults`. `BuildEnv` refuses to
read keys that are not in the schema.

## Adding a key

1. Add the constant in `env_keys.dart`.
2. Add the `String.fromEnvironment` in `build_env_values.dart`.
3. Add the `EnvKeySpec` in `env_schema.dart`.
4. Add the key to the `env/*.example.json` files.
5. Add the key to `EnvSchema.activeNames` if needed.

## Validation

`EnvModule.ready` runs the validator. All empty required keys are reported at
once, so the application does not fail one at a time.

## Debug

`EnvDebugPage` shows the active keys and masks secret values. This page is
automatically hidden in the production flavor.
