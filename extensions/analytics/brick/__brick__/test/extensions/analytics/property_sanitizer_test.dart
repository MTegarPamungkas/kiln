import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/analytics/property_sanitizer.dart';

enum _Status { active }

void main() {
  const sanitizer = PropertySanitizer();

  group('PropertySanitizer', () {
    test('converts supported values to JSON-like values', () {
      final result = sanitizer.sanitize(<String, Object?>{
        'text': 'hello',
        'count': 2,
        'ratio': 1.5,
        'enabled': true,
        'status': _Status.active,
        'created_at': DateTime.utc(2026, 5, 6, 7, 8, 9),
        'elapsed': const Duration(seconds: 90),
        'tags': <String>['a', 'b'],
        'nested': <String, Object?>{'depth': 1},
      });

      expect(result, <String, Object?>{
        'text': 'hello',
        'count': 2,
        'ratio': 1.5,
        'enabled': true,
        'status': 'active',
        'created_at': '2026-05-06T07:08:09.000Z',
        'elapsed': 90000,
        'tags': <String>['a', 'b'],
        'nested': <String, Object?>{'depth': 1},
      });
    });

    test('drops null values at every level', () {
      final result = sanitizer.sanitize(<String, Object?>{
        'top': null,
        'nested': <String, Object?>{'keep': 1, 'drop': null},
        'items': <Object?>[null, 'a', null],
      });

      expect(result, <String, Object?>{
        'nested': <String, Object?>{'keep': 1},
        'items': <String>['a'],
      });
    });

    test('does not mutate the input map', () {
      final input = <String, Object?>{'top': null, 'value': 1};

      sanitizer.sanitize(input);

      expect(input, <String, Object?>{'top': null, 'value': 1});
    });

    test('rejects unsupported values with a validation Failure', () {
      expect(
        () => sanitizer.sanitize(<String, Object?>{'callback': Object()}),
        throwsA(
          isA<Failure>()
              .having(
                (failure) => failure.code,
                'code',
                FailureCode.validationUnsupportedValue,
              )
              .having(
                (failure) => failure.kind,
                'kind',
                FailureKind.validation,
              )
              .having(
                (failure) => failure.details['property'],
                'property',
                'callback',
              ),
        ),
      );
    });

    test('rejects non-string map keys', () {
      expect(
        () => sanitizer.sanitize(<String, Object?>{
          'meta': <Object?, Object?>{1: 'one'},
        }),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.details['property'],
            'property',
            'meta',
          ),
        ),
      );
    });

    test('rejects non-finite numbers', () {
      expect(
        () => sanitizer.sanitize(<String, Object?>{'value': double.nan}),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.validationUnsupportedValue,
          ),
        ),
      );
    });

    test('rejects cyclic structures instead of recursing forever', () {
      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;

      expect(
        () => sanitizer.sanitize(cyclic),
        throwsA(
          isA<Failure>()
              .having(
                (failure) => failure.kind,
                'kind',
                FailureKind.validation,
              )
              .having(
                (failure) => failure.details['property'],
                'property',
                'self',
              ),
        ),
      );
    });
  });
}
