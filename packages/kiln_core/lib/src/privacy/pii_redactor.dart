import 'dart:collection';

/// Masks personal data before it reaches a log, analytics, or crash sink.
final class PiiRedactor {
  const PiiRedactor({
    this.sensitiveKeys = defaultSensitiveKeys,
    this.replacement = '[redacted]',
    this.maxDepth = 12,
    this.maxEntries = 200,
    this.maxTextLength = 16384,
  }) : assert(maxDepth >= 0),
       assert(maxEntries > 0),
       assert(maxTextLength > 0);

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
  final int maxDepth;
  final int maxEntries;
  final int maxTextLength;

  bool isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return sensitiveKeys.any(lower.contains);
  }

  Object? redact(Object? value) => _redact(
    value,
    0,
    HashSet<Object>.identity(),
    _RedactionBudget(maxEntries),
  );

  Object? _redact(
    Object? value,
    int depth,
    Set<Object> parents,
    _RedactionBudget budget,
  ) {
    if (depth > maxDepth || budget.remaining-- <= 0) return replacement;
    if (value == null) {
      return null;
    }
    if (value is String) {
      return redactText(value);
    }
    if (value is Map) {
      if (!parents.add(value)) return replacement;
      try {
        final output = <String, Object?>{};
        for (final entry in value.entries) {
          if (budget.remaining <= 0) break;
          final key =
              entry.key is String || entry.key is num || entry.key is bool
              ? '${entry.key}'
              : replacement;
          if (isSensitiveKey(key) || key.length > maxTextLength) {
            budget.remaining--;
            output[key.length > maxTextLength ? replacement : key] =
                replacement;
          } else {
            output[key] = _redact(entry.value, depth + 1, parents, budget);
          }
        }
        return output;
      } finally {
        parents.remove(value);
      }
    }
    if (value is Iterable) {
      if (!parents.add(value)) return replacement;
      try {
        final output = <Object?>[];
        for (final item in value) {
          if (budget.remaining <= 0) break;
          output.add(_redact(item, depth + 1, parents, budget));
        }
        return output;
      } finally {
        parents.remove(value);
      }
    }
    return value;
  }

  Map<String, Object?> redactMap(Map<String, Object?> input) {
    final result = redact(input);
    return result is Map<String, Object?> ? result : {};
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
    // Drop oversized text entirely rather than exposing a truncated token.
    if (input.length > maxTextLength) return replacement;
    return input
        .replaceAll(_bearer, 'Bearer $replacement')
        .replaceAll(_jwt, replacement)
        .replaceAll(_email, replacement);
  }
}

final class _RedactionBudget {
  _RedactionBudget(this.remaining);
  int remaining;
}
