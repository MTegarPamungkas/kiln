import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'cycles are replaced while repeated non-cyclic values remain usable',
    () {
      final map = <String, Object?>{};
      final list = <Object?>[map];
      map['cycle'] = list;
      final shared = {'token': 'private'};
      final result = const PiiRedactor().redact({
        'loop': map,
        'a': shared,
        'b': shared,
      });
      expect(result, {
        'loop': {
          'cycle': ['[redacted]'],
        },
        'a': {'token': '[redacted]'},
        'b': {'token': '[redacted]'},
      });
    },
  );

  test('nested maps may have non-string keys', () {
    expect(
      const PiiRedactor().redact({
        1: {'password': 'private'},
      }),
      {
        '1': {'password': '[redacted]'},
      },
    );
  });

  test('depth, iterable work and text are bounded', () {
    const redactor = PiiRedactor(maxDepth: 1, maxEntries: 5, maxTextLength: 8);
    expect(
      redactor.redact({
        'a': {'b': 'private'},
      }),
      {
        'a': {'b': '[redacted]'},
      },
    );
    expect(redactor.redact(Iterable<int>.generate(1000000)), [0, 1, 2, 3]);
    expect(redactor.redactText('very long secret'), '[redacted]');
  });

  group('PiiRedactor', () {
    const redactor = PiiRedactor();

    test('masks sensitive keys regardless of case', () {
      final redacted = redactor.redactMap({
        'email': 'user@kiln.dev',
        'Password': 'hunter2',
        'profile': {'name': 'Tegar', 'api_key': 'sk_live_123'},
        'tags': ['public', 'user@kiln.dev'],
      });

      expect(redacted['email'], '[redacted]');
      expect(redacted['Password'], '[redacted]');
      expect(redacted['profile'], {'name': 'Tegar', 'api_key': '[redacted]'});
      expect(redacted['tags'], ['public', '[redacted]']);
    });

    test('masks secrets inside free text', () {
      expect(
        redactor.redactText('contact user@kiln.dev now'),
        'contact [redacted] now',
      );
      expect(
        redactor.redactText('Authorization: Bearer abc.def.ghi'),
        'Authorization: Bearer [redacted]',
      );
      expect(
        redactor.redactText(
          'jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.signature',
        ),
        'jwt [redacted]',
      );
      expect(redactor.redactText('plain message'), 'plain message');
    });

    test('masks sensitive headers and text in other headers', () {
      final redacted = redactor.redactHeaders({
        'Authorization': 'Bearer token-value',
        'X-Api-Key': 'key-value',
        'X-Contact': 'user@kiln.dev',
        'Accept': 'application/json',
      });

      expect(redacted['Authorization'], '[redacted]');
      expect(redacted['X-Api-Key'], '[redacted]');
      expect(redacted['X-Contact'], '[redacted]');
      expect(redacted['Accept'], 'application/json');
    });

    test('supports a custom sensitive key set and replacement', () {
      const custom = PiiRedactor(
        sensitiveKeys: {'nickname'},
        replacement: '***',
      );

      final redacted = custom.redactMap({'nickname': 'tegar', 'plan': 'free'});

      expect(redacted['nickname'], '***');
      expect(redacted['plan'], 'free');
    });

    test('keeps non-sensitive values unchanged', () {
      expect(redactor.redact(42), 42);
      expect(redactor.redact(true), isTrue);
      expect(redactor.redact(null), isNull);
      expect(redactor.redactMap({'count': 3})['count'], 3);
    });
  });
}
