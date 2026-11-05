import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/codegen/json_converters.dart';

void main() {
  group('json converters', () {
    test('epoch DateTime round trips through millis', () {
      const converter = EpochDateTimeConverter();
      final when = DateTime.utc(2020, 1, 2, 3, 4, 5);

      final millis = converter.toJson(when);

      expect(converter.fromJson(millis), when);
    });

    test('nullable epoch passes null through', () {
      const converter = NullableEpochDateTimeConverter();

      expect(converter.fromJson(null), isNull);
      expect(converter.toJson(null), isNull);
    });

    test('Duration round trips through milliseconds', () {
      const converter = DurationMillisConverter();
      const duration = Duration(minutes: 1, seconds: 30);

      expect(converter.fromJson(converter.toJson(duration)), duration);
    });

    test('Uri converter parses valid and nullifies invalid', () {
      const converter = UriStringConverter();

      expect(converter.fromJson('https://example.test/x')?.host,
          'example.test');
      expect(converter.fromJson(null), isNull);
      expect(converter.toJson(Uri.parse('https://a.test')), 'https://a.test');
    });
  });
}
