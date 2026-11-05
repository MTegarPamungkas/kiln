# build_runner workflow

The install `post_gen` hook runs generation once, but day-to-day you drive it
yourself.

## One-shot build

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Watch mode

While iterating on models, regenerate on save:

```sh
dart run build_runner watch --delete-conflicting-outputs
```

## What gets committed

The `.g.dart` and `.freezed.dart` files are committed so that `dart analyze`,
`flutter test`, and CI never need to run code generation. A model change is not
complete until its generated files are regenerated and committed alongside it.

If your CI must prove generation is current, add a step such as:

```sh
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code -- '*.g.dart' '*.freezed.dart'
```

The exit code is non-zero when the committed output is stale.
