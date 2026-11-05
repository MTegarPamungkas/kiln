import 'dart:convert';

/// JSON encoding helpers used by typed keys and TTL storage.
final class JsonCodec {
  const JsonCodec();

  String encode(Object? value) => jsonEncode(value);

  Object? decode(String value) => jsonDecode(value);
}
