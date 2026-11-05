/// Masks personal data before it reaches a log, analytics, or crash sink.
final class PiiRedactor {
  const PiiRedactor({
    this.sensitiveKeys = defaultSensitiveKeys,
    this.replacement = '[redacted]',
  });

  static const Set<String> defaultSensitiveKeys = <String>{
    'password',
    'passwd',
    'secret',
    'token',
    'authorization',
    'api_key',
    'api-key',
    'apikey',
    'access_key',
    'refresh_key',
    'dsn',
    'cookie',
    'session',
    'email',
    'phone',
    'ssn',
    'credit_card',
  };

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  static final RegExp _bearer = RegExp(
    r'Bearer\s+[A-Za-z0-9._~+/=-]+',
    caseSensitive: false,
  );
  static final RegExp _jwt = RegExp(
    r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
  );

  final Set<String> sensitiveKeys;
  final String replacement;

  bool isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return sensitiveKeys.any(lower.contains);
  }

  Object? redact(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return redactText(value);
    }
    if (value is Map) {
      return redactMap(Map<String, Object?>.from(value));
    }
    if (value is Iterable) {
      return value.map(redact).toList(growable: false);
    }
    return value;
  }

  Map<String, Object?> redactMap(Map<String, Object?> input) {
    final output = <String, Object?>{};
    for (final entry in input.entries) {
      output[entry.key] = isSensitiveKey(entry.key)
          ? replacement
          : redact(entry.value);
    }
    return output;
  }

  Map<String, String> redactHeaders(Map<String, String> headers) {
    final output = <String, String>{};
    for (final entry in headers.entries) {
      output[entry.key] = isSensitiveKey(entry.key)
          ? replacement
          : redactText(entry.value);
    }
    return output;
  }

  String redactText(String input) {
    return input
        .replaceAll(_bearer, 'Bearer $replacement')
        .replaceAll(_jwt, replacement)
        .replaceAll(_email, replacement);
  }
}
