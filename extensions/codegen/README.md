# Codegen

JSON model code generation for Kiln apps. Installing `codegen` wires
[`json_serializable`](https://pub.dev/packages/json_serializable) and
[`freezed`](https://pub.dev/packages/freezed) into your project with a shared
`build.yaml`, a set of epoch/URI/Duration `JsonConverter`s, and a sample model
that demonstrates a full `freezed` + JSON round trip. It is the only Kiln
extension that uses install hooks: a `post_gen` hook runs `build_runner` right
after the templates land (gated by the hook trust policy).

Codegen is a build-time tooling extension — it has no runtime service or Gate;
your models are ordinary Dart classes you write in your own `lib/`.

## Install

```sh
kiln add codegen
```

The installer asks which **generators** to enable (`json_serializable`,
`freezed`, or both — default both). Because this ships an official hook, hooks
run only when you approve them (`kiln add codegen --yes`), and they execute
`build_runner` once. If you skip the hook, run it yourself:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## What it adds

- `build.yaml` — `json_serializable` configured with `explicit_to_json` and
  snake-case field renaming.
- `lib/extensions/codegen/json_converters.dart` — `EpochDateTimeConverter`,
  `NullableEpochDateTimeConverter`, `DurationMillisConverter`, and
  `UriStringConverter` for `@JsonKey(converter: ...)`.
- `lib/extensions/codegen/example/example_model.dart` — a `@freezed` model with
  committed generated output, as a copy-me template.
- `dependencies` `json_annotation` + `freezed_annotation`, and dev dependencies
  `build_runner`, `json_serializable`, `freezed`.

## Committing generated output

The `.g.dart` and `.freezed.dart` files are checked in so analysis and CI do not
need to run code generation. Re-run `build_runner` whenever you edit a model.

See `docs/json-models.md` and `docs/build-runner-workflow.md` for the day-to-day
workflow.
