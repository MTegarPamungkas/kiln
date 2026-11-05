# Codegen

`codegen` gives a Kiln app a ready-made model-serialization setup:
`json_serializable` for plain classes and `freezed` for immutable classes with
`copyWith`, equality, and unions. Both are configured through one `build.yaml`,
and a shared library of `JsonConverter`s handles the scalar types JSON has no
natural representation for.

This extension is build-time only. It does not register a runtime service and
adds no Gate verbs — you use it by annotating your own models and running
`build_runner`.

## Why it is an extension

Rather than every app copy-pasting the same `build.yaml`, dev dependencies, and
converter classes, `kiln add codegen` writes them once and keeps them
conservative:

- `explicit_to_json: true` so nested models serialize without reflection.
- `field_rename: snake` to match typical REST/JSON payloads.
- `EpochDateTimeConverter` because Sentry, Appwrite, and many REST APIs use epoch
  time, not ISO strings.

See `json-models.md` for authoring and `build-runner-workflow.md` for generation.
