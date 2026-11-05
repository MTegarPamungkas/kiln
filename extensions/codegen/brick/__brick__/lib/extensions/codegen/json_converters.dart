import 'package:json_annotation/json_annotation.dart';

/// Converts a [DateTime] to and from Unix epoch milliseconds.
///
/// Sentry, Appwrite, and many REST payloads use epoch time, so models annotated
/// with this converter survive a JSON round trip without ISO string juggling.
class EpochDateTimeConverter implements JsonConverter<DateTime, int> {
  const EpochDateTimeConverter();

  @override
  DateTime fromJson(int json) =>
      DateTime.fromMillisecondsSinceEpoch(json, isUtc: true);

  @override
  int toJson(DateTime object) => object.toUtc().millisecondsSinceEpoch;
}

/// Nullable companion of [EpochDateTimeConverter].
class NullableEpochDateTimeConverter
    implements JsonConverter<DateTime?, int?> {
  const NullableEpochDateTimeConverter();

  @override
  DateTime? fromJson(int? json) => json == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(json, isUtc: true);

  @override
  int? toJson(DateTime? object) => object?.toUtc().millisecondsSinceEpoch;
}

/// Converts a [Duration] to and from an integer number of milliseconds.
class DurationMillisConverter implements JsonConverter<Duration, int> {
  const DurationMillisConverter();

  @override
  Duration fromJson(int json) => Duration(milliseconds: json);

  @override
  int toJson(Duration object) => object.inMilliseconds;
}

/// Reads a [Uri] from a string, returning null when it cannot be parsed.
class UriStringConverter implements JsonConverter<Uri?, String?> {
  const UriStringConverter();

  @override
  Uri? fromJson(String? json) => json == null ? null : Uri.tryParse(json);

  @override
  String? toJson(Uri? object) => object?.toString();
}
