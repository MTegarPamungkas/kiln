import 'package:kiln_core/kiln_core.dart';

/// Converts event properties and identity traits into JSON-like values.
///
/// Supported values are `null`, strings, booleans, finite numbers,
/// [DateTime], [Duration], [Enum], maps with string keys, and iterables of
/// supported values. Null entries are dropped and anything else raises a
/// [Failure] with [FailureKind.validation].
final class PropertySanitizer {
  const PropertySanitizer();

  /// Returns a sanitized copy of [properties].
  Map<String, Object?> sanitize(Map<String, Object?> properties) {
    final sanitized = _sanitizeMap(
      properties,
      path: '',
      seen: Set<Object>.identity(),
    );
    return sanitized;
  }

  Map<String, Object?> _sanitizeMap(
    Map<Object?, Object?> input, {
    required String path,
    required Set<Object> seen,
  }) {
    if (!seen.add(input)) {
      throw _unsupported(path.isEmpty ? '<root>' : path, 'cyclic map');
    }
    final output = <String, Object?>{};
    try {
      for (final entry in input.entries) {
        final key = entry.key;
        if (key is! String) {
          throw _unsupported(
            path.isEmpty ? '<root>' : path,
            'map key of type ${key.runtimeType}',
          );
        }
        final childPath = path.isEmpty ? key : '$path.$key';
        final value = _sanitizeValue(entry.value, path: childPath, seen: seen);
        if (value != null) {
          output[key] = value;
        }
      }
    } finally {
      seen.remove(input);
    }
    return output;
  }

  Object? _sanitizeValue(
    Object? value, {
    required String path,
    required Set<Object> seen,
  }) {
    if (value == null) {
      return null;
    }
    if (value is String || value is bool) {
      return value;
    }
    if (value is num) {
      if (value is double && !value.isFinite) {
        throw _unsupported(path, 'non-finite number');
      }
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Duration) {
      return value.inMilliseconds;
    }
    if (value is Enum) {
      return value.name;
    }
    if (value is Map) {
      return _sanitizeMap(value, path: path, seen: seen);
    }
    if (value is Iterable) {
      if (!seen.add(value)) {
        throw _unsupported(path, 'cyclic iterable');
      }
      try {
        final output = <Object?>[];
        var index = 0;
        for (final item in value) {
          final sanitized = _sanitizeValue(
            item,
            path: '$path[$index]',
            seen: seen,
          );
          if (sanitized != null) {
            output.add(sanitized);
          }
          index++;
        }
        return output;
      } finally {
        seen.remove(value);
      }
    }
    throw _unsupported(path, '${value.runtimeType}');
  }

  Failure _unsupported(String path, String type) {
    return Failure(
      code: FailureCode.validationUnsupportedValue,
      message: 'Analytics property "$path" has an unsupported value ($type).',
      kind: FailureKind.validation,
      details: <String, Object?>{'property': path, 'type': type},
    );
  }
}
