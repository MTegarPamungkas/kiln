# Troubleshooting

## Conflicting outputs

`build_runner` refuses to overwrite files it did not generate. Use
`--delete-conflicting-outputs` to let it reclaim stale `.g.dart`/`.freezed.dart`
files, then re-run.

## Analyzer or generator version mismatch

`freezed` and `json_serializable` track specific `analyzer` and SDK versions. If
generation fails with an analyzer or builder version error:

- `flutter pub upgrade json_serializable freezed build_runner`
- ensure the SDK constraint matches the Flutter channel you are on
- pin generator versions in your app's `pubspec.yaml` so teammates and CI agree

## `part` errors

Every freezed+JSON model needs both directives, in this order:

```dart
part 'model.freezed.dart';
part 'model.g.dart';
```

If the analyzer reports the part files do not exist, you have not run
`build_runner` since adding the directives. Run the one-shot build.

## `@JsonKey` on a freezed field

Use converter/`@JsonKey` on the factory parameters (the constructor), not on the
private `_Model` class — freezed copies the annotations into generated code from
the public factory.
