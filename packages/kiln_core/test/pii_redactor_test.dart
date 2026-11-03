import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
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
