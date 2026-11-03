import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// Wraps a [Storage] and expires values after a time-to-live.
final class TtlStorage implements Storage {
  TtlStorage({
    required this.inner,
    required this.clock,
    this.defaultTtl = const Duration(days: 1),
  });

  final Storage inner;
  final Clock clock;
  final Duration defaultTtl;

  @override
  Future<String?> read(String key) async {
    final raw = await inner.read(key);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final expiresAt = DateTime.tryParse('${decoded['expiresAt'] ?? ''}');
      if (expiresAt == null || !expiresAt.isAfter(clock.now().toUtc())) {
        await inner.delete(key);
        return null;
      }
      return '${decoded['value']}';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(
    String key,
    String value, {
    Duration? ttl,
  }) {
    final expiresAt = clock.now().toUtc().add(ttl ?? defaultTtl);
    return inner.write(
      key,
      jsonEncode(<String, Object?>{
        'value': value,
        'expiresAt': expiresAt.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> delete(String key) => inner.delete(key);

  @override
  Future<bool> containsKey(String key) async => await read(key) != null;

  @override
  Future<Set<String>> keys() async {
    final result = <String>{};
    for (final key in await inner.keys()) {
      if (await read(key) != null) {
        result.add(key);
      }
    }
    return result;
  }

  @override
  Future<void> clear() => inner.clear();
}
