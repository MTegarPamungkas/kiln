import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// A typed key stored as JSON.
final class StorageKey<T> {
  const StorageKey({
    required this.name,
    required this.encode,
    required this.decode,
    this.defaultValue,
  });

  final String name;
  final Object? Function(T value) encode;
  final T Function(Object? value) decode;
  final T? defaultValue;

  Future<T?> read(Storage storage) async {
    final raw = await storage.read(name);
    if (raw == null) {
      return defaultValue;
    }
    return decode(jsonDecode(raw));
  }

  Future<void> write(Storage storage, T value) {
    return storage.write(name, jsonEncode(encode(value)));
  }

  Future<void> delete(Storage storage) => storage.delete(name);
}
