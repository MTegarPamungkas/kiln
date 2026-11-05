import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/env/env_schema.dart';

void main() {
  test('every schema key exists in every example file', () {
    final schema = EnvSchema.defaults;
    for (final file in <String>[
      'env/development.example.json',
      'env/staging.example.json',
      'env/production.example.json',
    ]) {
      final decoded = jsonDecode(File(file).readAsStringSync());
      expect(decoded, isA<Map<String, Object?>>(), reason: file);
      final map = decoded as Map<String, Object?>;
      for (final key in schema.keys) {
        expect(
          map.containsKey(key.name),
          isTrue,
          reason: '$file is missing ${key.name}',
        );
      }
    }
  });
}
