# Flavors and environments

End goal:

- `flavors` provides `AppFlavor` and a non-production banner through the
  `app.wrappers` slot.
- `env` provides a typed `Env` and `env/*.example.json` files.
- Real values live in `env/<flavor>.json` and are ignored by Git.
- Run with `--dart-define-from-file=env/<flavor>.json`.

Example config:

```yaml
extensions:
  env:
    keys:
      - {name: API_BASE_URL, type: url, required: true}
      - {name: ENABLE_LOGGING, type: bool, required: false}
```

Remember: `--dart-define` values can be extracted from the binary, so do not
store server keys in a client application.

The `flavors` and `env` extensions land in the tooling phase of the
[roadmap](../roadmap.md).
