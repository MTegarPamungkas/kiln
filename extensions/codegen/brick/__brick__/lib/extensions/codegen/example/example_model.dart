import 'package:freezed_annotation/freezed_annotation.dart';

import '../json_converters.dart';

part 'example_model.freezed.dart';
part 'example_model.g.dart';

/// A JSON round-trip model that exercises both generators at once: `freezed`
/// generates the immutable class and `json_serializable` generates the
/// `fromJson`/`toJson` helpers, with the shared converters handling non-string
/// scalars. Copy it as a template for your own models.
@freezed
abstract class ExampleModel with _$ExampleModel {
  const factory ExampleModel({
    required String id,
    required int itemCount,
    @NullableEpochDateTimeConverter() DateTime? createdAt,
    @UriStringConverter() Uri? link,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(Map<String, Object?> json) =>
      _$ExampleModelFromJson(json);
}
