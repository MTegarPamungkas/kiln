# Writing JSON models

Copy `lib/extensions/codegen/example/example_model.dart` as a starting point.

## freezed + json

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../json_converters.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    @NullableEpochDateTimeConverter() DateTime? createdAt,
    @UriStringConverter() Uri? avatarUrl,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
```

`field_rename: snake` means `createdAt` maps to `created_at` and `avatarUrl` to
`avatar_url` automatically. `explicit_to_json: true` means nested models must
expose their own `toJson`, which `freezed` does when they carry `fromJson`.

## Converters

The shipped converters plug into `@JsonKey(converter: ...)`:

| Converter | JSON | Notes |
| --- | --- | --- |
| `EpochDateTimeConverter` | integer millis | non-null `DateTime` |
| `NullableEpochDateTimeConverter` | nullable millis | passes `null` through |
| `DurationMillisConverter` | integer millis | `Duration.inMilliseconds` |
| `UriStringConverter` | string or null | nullifies unparsable input |

Regenerate after every model change — see `build-runner-workflow.md`.
